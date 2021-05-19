//
//  EntriesCollectionViewController.swift
//  FilesTree
//
//  Created by Dmitry Reshetnik on 13.05.2021.
//

import UIKit
import GoogleSignIn

private let gridReuseIdentifier = "GridEntry"
private let columnReuseIdentifier = "ColumnEntry"

enum Layout {
    static let layoutUpdatedNotification = Notification.Name("Layout.Updated")
    
    case grid, column
}

class EntriesCollectionViewController: UICollectionViewController {
    @IBOutlet var layoutButton: UIBarButtonItem!
    
    @IBAction func switchLayout(_ sender: UIBarButtonItem) {
        switch activeLayout {
            case .grid:
                activeLayout = .column
            case .column:
                activeLayout = .grid
        }
    }
    
    @IBAction func addDirectory(_ sender: UIBarButtonItem) {
        let entry = Entry(itemID: UUID(), parentItemID: rootEntryID, itemType: .directory, itemName: "Test Directory")
        entries.append(entry)
        entriesTree[entry.itemID] = entry
        service.updateValues(with: constructValues(from: entries))
        updateUI()
    }
    
    @IBAction func addFile(_ sender: UIBarButtonItem) {
        let entry = Entry(itemID: UUID(), parentItemID: rootEntryID, itemType: .file, itemName: "Test File")
        entries.append(entry)
        entriesTree[entry.itemID] = entry
        service.updateValues(with: constructValues(from: entries))
        updateUI()
    }
    
    var rootEntryID: UUID?
    var entries: [Entry] = []
    var entriesTree: [UUID: Entry] = [:]
    var layout: [Layout: UICollectionViewLayout] = [:]
    var activeLayout: Layout = .grid {
        didSet {
            if let layout = layout[activeLayout] {
                self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
                
                self.collectionView.setCollectionViewLayout(layout, animated: true)
                
                NotificationCenter.default.post(name: Layout.layoutUpdatedNotification, object: nil)
            }
        }
    }
    
    let service = GoogleSheetsService()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateSignInButton), name: App.stateUpdatedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateLayoutButton), name: Layout.layoutUpdatedNotification, object: nil)
        
        // Automatically sign in the user.
        GIDSignIn.sharedInstance()?.restorePreviousSignIn()
        
        layout[.grid] = generateGridLayout()
        layout[.column] = generateColumnLayout()
        
        if let layout = layout[activeLayout] {
            collectionView.collectionViewLayout = layout
        }
        
        if self.navigationController!.viewControllers.count == 1 {
            let signInButton = UIBarButtonItem(image: UIImage(systemName: "person"), style: .plain, target: self, action: #selector(signIn))
            navigationItem.leftBarButtonItem = signInButton
        }
        
        if entriesTree.isEmpty && entries.isEmpty {
            service.getValues { result in
                switch result {
                    case .success(let values):
                        self.constructEntriesTree(from: values)
                        DispatchQueue.main.async {
                            self.updateUI()
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                }
            }
        } else {
            updateUI()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Must be set each time to prevent "presentingViewController must be set." runtime crash.
        GIDSignIn.sharedInstance()?.presentingViewController = self
    }
    
    func generateColumnLayout() -> UICollectionViewLayout {
        let padding: CGFloat = 5
        
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(44)), subitems: [item])
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: padding, bottom: 0, trailing: padding)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 2
        section.contentInsets = NSDirectionalEdgeInsets(top: padding, leading: 0, bottom: padding, trailing: 0)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    func generateGridLayout() -> UICollectionViewLayout {
        let padding: CGFloat = 5
        
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1/6)), subitem: item, count: 3)
        group.interItemSpacing = .fixed(padding)
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: padding, bottom: 0, trailing: padding)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = padding
        section.contentInsets = NSDirectionalEdgeInsets(top: padding, leading: 0, bottom: padding, trailing: 0)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    func updateUI() {
        updateLayoutButton()
        updateSignInButton()
        collectionView.reloadData()
    }
    
    @objc func signIn() {
        switch App.sharedInstance.state {
            case .unauthorized:
                GIDSignIn.sharedInstance().signIn()
            case .authorized:
                GIDSignIn.sharedInstance().signOut()
                App.sharedInstance.state = .unauthorized
        }
    }
    
    @objc func updateLayoutButton() {
        switch activeLayout {
            case .grid:
                self.layoutButton.image = UIImage(systemName: "square.grid.2x2")
            case .column:
                self.layoutButton.image = UIImage(systemName: "list.dash")
        }
    }
    
    @objc func updateSignInButton() {
        switch App.sharedInstance.state {
            case .authorized:
                self.navigationItem.leftBarButtonItem?.image = UIImage(systemName: "person.fill")
            case .unauthorized:
                self.navigationItem.leftBarButtonItem?.image = UIImage(systemName: "person")
        }
    }
    
    func constructEntriesTree(from values: [[String]]) {
        for value in values {
            guard let uuid = UUID(uuidString: value[0]) else {
                continue // Protect from incorrect data or it corruption in source Google Sheets File.
            }
            
            let entry = Entry(itemID: uuid, parentItemID: UUID(uuidString: value[1]), itemType: value[2] == "f" ? .file : .directory, itemName: value[3])
            entries.append(entry)
        }
        
        for entry in entries {
            if entry.parentItemID == nil {
                entriesTree[entry.itemID] = entry
            }
        }
    }
    
    func constructValues(from entries: [Entry]) -> [[String]] {
        var values: [[String]] = [[String]()]
        var initialIndex: Int = 0
        
        for entry in entries {
            values[initialIndex].append(entry.itemID.uuidString)
            values[initialIndex].append(entry.parentItemID?.uuidString ?? "")
            values[initialIndex].append(entry.itemType == .directory ? "d" : "f")
            values[initialIndex].append(entry.itemName)
            values.append([])
            initialIndex += 1
        }
        
        values.removeLast()
        
        return values
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return entriesTree.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = activeLayout == .grid ? gridReuseIdentifier : columnReuseIdentifier
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! EntryCollectionViewCell
    
        if !entriesTree.values.sorted().isEmpty {
            let entry = entriesTree.values.sorted()[indexPath.item]
            cell.update(with: entry, for: activeLayout)
        }
        
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard entriesTree.values.sorted()[indexPath.item].itemType != .file else {
            return
        }
        
        var childEntriesTree: [UUID: Entry] = [:]
        
        for entry in entries {
            if entry.parentItemID == entriesTree.values.sorted()[indexPath.row].itemID {
                childEntriesTree[entry.itemID] = entry
            }
        }
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "EntriesViewController") as! EntriesCollectionViewController
        nextViewController.activeLayout = activeLayout
        nextViewController.entriesTree = childEntriesTree
        nextViewController.entries = entries
        nextViewController.rootEntryID = entriesTree.values.sorted()[indexPath.row].itemID
        nextViewController.navigationItem.title = entriesTree.values.sorted()[indexPath.row].itemName
        
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
