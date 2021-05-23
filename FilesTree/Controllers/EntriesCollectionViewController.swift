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
    let layoutButton: UIBarButtonItem = UIBarButtonItem()
    let addDirectoryButton: UIBarButtonItem = UIBarButtonItem()
    let addFileButton: UIBarButtonItem = UIBarButtonItem()
    let signInButton: UIBarButtonItem = UIBarButtonItem()
    let activityIndicator: SpinnerViewController = SpinnerViewController()
    
    var rootEntryID: UUID?
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register cell classes.
        collectionView.register(EntryCollectionViewCell.self, forCellWithReuseIdentifier: gridReuseIdentifier)
        collectionView.register(EntryCollectionViewCell.self, forCellWithReuseIdentifier: columnReuseIdentifier)
        collectionView.backgroundColor = .systemBackground
        
        // Add observers to Notification Center.
        NotificationCenter.default.addObserver(self, selector: #selector(updateSignInButton), name: App.stateUpdatedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(synchronizeDataSource), name: App.stateAuthorizedNotidication, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateLayoutButton), name: Layout.layoutUpdatedNotification, object: nil)
        
        // Generate appropriated layouts.
        layout[.grid] = generateGridLayout()
        layout[.column] = generateColumnLayout()
        
        // Set active layout.
        if let layout = layout[activeLayout] {
            collectionView.collectionViewLayout = layout
        }
        
        // Show sign in button in the root view controller.
        if self.navigationController?.viewControllers.count == 1 {
            signInButton.action = #selector(signIn)
            signInButton.target = self
            signInButton.image = UIImage(systemName: "person")
            navigationItem.leftBarButtonItem = signInButton
            updateSignInButton()
            title = "Entries"
        }
        
        // Adjust add file button item.
        addFileButton.action = #selector(addFile)
        addFileButton.target = self
        addFileButton.image = UIImage(systemName: "doc.badge.plus")
        
        // Adjust add directory button item.
        addDirectoryButton.action = #selector(addDirectory)
        addDirectoryButton.target = self
        addDirectoryButton.image = UIImage(systemName: "folder.badge.plus")
        
        // Adjust layout button item.
        layoutButton.action = #selector(switchLayout)
        layoutButton.target = self
        layoutButton.image = UIImage(systemName: "square.grid.2x2")
        
        navigationItem.rightBarButtonItems = [layoutButton, addDirectoryButton, addFileButton]
        
        // Fetch data at the application launch.
        if entriesTree.isEmpty && App.sharedInstance.entriesStore.isEmpty {
            // Add the spinner view controller.
            addChild(activityIndicator)
            activityIndicator.view.frame = view.frame
            view.addSubview(activityIndicator.view)
            activityIndicator.didMove(toParent: self)
            
            // Disable action buttons.
            navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = false }
            navigationItem.leftBarButtonItems?.forEach { $0.isEnabled = false }
            
            GoogleSheetsService.sharedInstance.getValues { result in
                switch result {
                    case .success(let values):
                        // There is no need to construct entries tree if "server" does not store values.
                        guard !values.first!.isEmpty else {
                            DispatchQueue.main.async {
                                self.activateUI()
                            }
                            
                            break
                        }
                        
                        self.constructEntriesTree(from: values)
                        
                        DispatchQueue.main.async {
                            self.activateUI()
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            let alertController = UIAlertController(title: "There was an error while fetching your entries.", message: error.localizedDescription, preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            self.present(alertController, animated: true, completion: nil)
                            self.activateUI()
                        }
                }
            }
        } else {
            updateUI()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard previousTraitCollection != nil else {
            return
        }
        
        collectionView?.collectionViewLayout.invalidateLayout()
        
        // Regenerate grid layout to change it heights to prevent shrinking in compact environment.
        if activeLayout == .grid {
            self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
            self.collectionView.setCollectionViewLayout(generateGridLayout(), animated: true)
        }
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
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(traitCollection.verticalSizeClass == .compact ? 128 : 144)), subitem: item, count: 3)
        group.interItemSpacing = .fixed(padding)
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: padding, bottom: 0, trailing: padding)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = padding
        section.contentInsets = NSDirectionalEdgeInsets(top: padding, leading: 0, bottom: padding, trailing: 0)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    func updateUI() {
        updateLayoutButton()
        collectionView.reloadData()
    }
    
    func activateUI() {
        // Remove the spinner view controller
        activityIndicator.willMove(toParent: nil)
        activityIndicator.view.removeFromSuperview()
        activityIndicator.removeFromParent()
        
        // Enable action buttons.
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = true }
        navigationItem.leftBarButtonItems?.forEach { $0.isEnabled = true }
        
        updateUI()
    }
    
    @objc func switchLayout() {
        switch activeLayout {
            case .grid:
                activeLayout = .column
            case .column:
                activeLayout = .grid
        }
    }
    
    @objc func addDirectory() {
        addEntryOf(type: .directory)
    }
    
    @objc func addFile() {
        addEntryOf(type: .file)
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
                self.signInButton.image = UIImage(systemName: "person.fill")
            case .unauthorized:
                self.signInButton.image = UIImage(systemName: "person")
        }
    }
    
    @objc func synchronizeDataSource() {
        // Update values to synchronize state of the remote data source after user has successfully signed in.
        GoogleSheetsService.sharedInstance.updateValues(with: constructValues(from: App.sharedInstance.entriesStore))
    }
    
    func constructEntriesTree(from values: [[String]]) {
        DispatchQueue.global(qos: .background).sync {
            var context = App.sharedInstance.entriesStore
            
            for value in values {
                guard let uuid = UUID(uuidString: value[0]) else {
                    continue // Protect from incorrect data or it corruption in source Google Sheets File.
                }
                
                let entry = Entry(itemID: uuid, parentItemID: UUID(uuidString: value[1]), itemType: value[2] == "f" ? .file : .directory, itemName: value[3])
                context.append(entry)
            }
            
            DispatchQueue.main.async {
                App.sharedInstance.entriesStore = context
                
                for entry in App.sharedInstance.entriesStore {
                    if entry.parentItemID == nil {
                        self.entriesTree[entry.itemID] = entry
                    }
                }
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
    
    func addEntryOf(type: Entry.ItemType) {
        DispatchQueue.global(qos: .background).sync {
            var context = App.sharedInstance.entriesStore
            
            let entriesNames = Array(self.entriesTree.values.filter { $0.itemType == type }.map { $0.itemName })
            let entry = Entry(itemID: UUID(), parentItemID: self.rootEntryID, itemType: type, itemName: "Untitled".madeUnique(withRespectTo: entriesNames))
            
            context.append(entry)
            
            DispatchQueue.main.async {
                App.sharedInstance.entriesStore = context
                self.entriesTree[entry.itemID] = entry
                self.updateUI()
                
                // Update values with Google Sheets Service only if user authorized.
                if App.sharedInstance.state == .authorized {
                    GoogleSheetsService.sharedInstance.updateValues(with: self.constructValues(from: App.sharedInstance.entriesStore))
                }
            }
        }
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
        
        for entry in App.sharedInstance.entriesStore {
            if entry.parentItemID == entriesTree.values.sorted()[indexPath.row].itemID {
                childEntriesTree[entry.itemID] = entry
            }
        }
        
        // Create and configure destination view controller for navigation segue.
        let nextViewController = EntriesCollectionViewController(collectionViewLayout: collectionView.collectionViewLayout)
        nextViewController.entriesTree = childEntriesTree
        nextViewController.activeLayout = activeLayout
        nextViewController.rootEntryID = entriesTree.values.sorted()[indexPath.item].itemID
        nextViewController.navigationItem.title = entriesTree.values.sorted()[indexPath.item].itemName
        
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { (elements) -> UIMenu? in
            let delete = UIAction(title: "Delete") { _ in
                self.deleteEntry(at: indexPath)
            }
            
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: [delete])
        }
        
        return config
    }

    func deleteEntry(at indexPath: IndexPath) {
        DispatchQueue.global(qos: .background).sync {
            var context = App.sharedInstance.entriesStore
            
            let entry = self.entriesTree.values.sorted()[indexPath.item]
            
            guard let index = context.firstIndex(where: { $0 == entry }) else {
                return
            }
            
            // Remove all subentries if type of the deleted entry is directory.
            if entry.itemType == .directory {
                context.removeAll { $0.parentItemID == entry.itemID }
            }
            
            context.remove(at: index)
            
            DispatchQueue.main.async {
                App.sharedInstance.entriesStore = context
                self.entriesTree[entry.itemID] = nil
                self.collectionView.deleteItems(at: [indexPath])
                self.updateUI()
                
                // Update values with Google Sheets Service only if user authorized.
                if App.sharedInstance.state == .authorized {
                    GoogleSheetsService.sharedInstance.updateValues(with: self.constructValues(from: App.sharedInstance.entriesStore))
                }
            }
        }
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
