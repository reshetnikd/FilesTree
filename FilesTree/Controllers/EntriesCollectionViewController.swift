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

class EntriesCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    let layoutButton: UIBarButtonItem = UIBarButtonItem()
    let addDirectoryButton: UIBarButtonItem = UIBarButtonItem()
    let addFileButton: UIBarButtonItem = UIBarButtonItem()
    let signInButton: UIBarButtonItem = UIBarButtonItem()
    let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .large)
    let collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewCompositionalLayout.list(using: UICollectionLayoutListConfiguration(appearance: .plain)))
    
    private var entries: [Entry] = []
    var rootEntryID: UUID?
    var entriesTree: [UUID: Entry] = [:] {
        didSet {
            self.entries = self.entriesTree.values.sorted()
        }
    }
    
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
        
        // Setup collection view.
        collectionView.frame = view.bounds
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
        ])
        
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
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.hidesWhenStopped = true
            activityIndicator.startAnimating()
            view.addSubview(activityIndicator)
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
            
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
                        
                        self.entriesTree = GoogleSheetsService.sharedInstance.constructEntriesTree(from: values)
                        
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        collectionView.frame = view.bounds
        collectionView.collectionViewLayout.invalidateLayout()
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
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(144)), subitem: item, count: 3)
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
        activityIndicator.stopAnimating()
        
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
                layoutButton.image = UIImage(systemName: "square.grid.2x2")
            case .column:
                layoutButton.image = UIImage(systemName: "list.dash")
        }
    }
    
    @objc func updateSignInButton() {
        switch App.sharedInstance.state {
            case .authorized:
                signInButton.image = UIImage(systemName: "person.fill")
            case .unauthorized:
                signInButton.image = UIImage(systemName: "person")
        }
    }
    
    @objc func synchronizeDataSource() {
        // Update values to synchronize state of the remote data source after user has successfully signed in.
        GoogleSheetsService.sharedInstance.updateValues(with: GoogleSheetsService.sharedInstance.constructValues(from: App.sharedInstance.entriesStore))
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
                    GoogleSheetsService.sharedInstance.updateValues(with: GoogleSheetsService.sharedInstance.constructValues(from: App.sharedInstance.entriesStore))
                }
            }
        }
    }

    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return entriesTree.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = activeLayout == .grid ? gridReuseIdentifier : columnReuseIdentifier
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! EntryCollectionViewCell
    
        if !entries.isEmpty {
            let entry = entries[indexPath.item]
            cell.update(with: entry, for: activeLayout)
        }
        
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard entries[indexPath.item].itemType != .file else {
            return
        }
        
        var childEntriesTree: [UUID: Entry] = [:]
        
        for entry in App.sharedInstance.entriesStore {
            if entry.parentItemID == entries[indexPath.row].itemID {
                childEntriesTree[entry.itemID] = entry
            }
        }
        
        // Create and configure destination view controller for navigation segue.
        let nextViewController = EntriesCollectionViewController()
        nextViewController.entriesTree = childEntriesTree
        nextViewController.activeLayout = activeLayout
        nextViewController.rootEntryID = entries[indexPath.item].itemID
        nextViewController.navigationItem.title = entries[indexPath.item].itemName
        
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
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
            
            let entry = self.entries[indexPath.item]
            
            guard let index = context.firstIndex(where: { $0 == entry }) else {
                return
            }
            
            context.remove(at: index)
            
            // Remove all subentries if type of the deleted entry is directory.
            if entry.itemType == .directory {
                // Significantly better performance.
//                context = Array(Set(context).subtracting(extractSubentires(from: context, with: entry.itemID)))
                
                // Preserves ordering in source Google Sheets File.
                context = context.filter { !extractSubentires(from: context, with: entry.itemID).contains($0) }
            }
            
            DispatchQueue.main.async {
                App.sharedInstance.entriesStore = context
                self.entriesTree[entry.itemID] = nil
                self.collectionView.deleteItems(at: [indexPath])
                self.updateUI()
                
                // Update values with Google Sheets Service only if user authorized.
                if App.sharedInstance.state == .authorized {
                    GoogleSheetsService.sharedInstance.deleteValues(with: GoogleSheetsService.sharedInstance.constructValues(from: App.sharedInstance.entriesStore))
                }
            }
        }
    }
    
    func extractSubentires(from entries: [Entry], with id: UUID) -> [Entry] {
        var foundEntries: [Entry] = []
        
        for entry in entries {
            if entry.hasParentID(id) {
                foundEntries.append(entry)
                foundEntries += extractSubentires(from: entries, with: entry.itemID)
            }
        }
        
        return foundEntries
    }

}
