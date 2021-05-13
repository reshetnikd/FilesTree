//
//  EntriesCollectionViewController.swift
//  FilesTree
//
//  Created by Dmitry Reshetnik on 13.05.2021.
//

import UIKit

private let gridReuseIdentifier = "GridEntry"
private let columnReuseIdentifier = "ColumnEntry"

class EntriesCollectionViewController: UICollectionViewController {
    @IBOutlet var layoutButton: UIBarButtonItem!
    
    @IBAction func switchLayout(_ sender: UIBarButtonItem) {
        
    }
    
    enum Layout {
        case grid, column
    }
    
    var entries: [Entry] = []
    var entriesTree: [UUID: Entry] = [:]
    var layout: [Layout: UICollectionViewLayout] = [:]
    var activeLayout: Layout = .grid {
        didSet {
            if let layout = layout[activeLayout] {
                self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
                
                self.collectionView.setCollectionViewLayout(layout, animated: true) { _ in
                    switch self.activeLayout {
                        case .grid:
                            self.layoutButton.image = UIImage(systemName: "square.grid.2x2")
                        case .column:
                            self.layoutButton.image = UIImage(systemName: "list.dash")
                    }
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        layout[.grid] = generateGridLayout()
        layout[.column] = generateColumnLayout()
        
        if let layout = layout[activeLayout] {
            collectionView.collectionViewLayout = layout
        }
        
        if entriesTree.isEmpty && entries.isEmpty {
            fetchData()
        } else {
            updateUI()
        }
    }
    
    func generateColumnLayout() -> UICollectionViewLayout {
        let padding: CGFloat = 10
        
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(120)), subitems: [item])
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: padding, bottom: 0, trailing: padding)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = padding
        section.contentInsets = NSDirectionalEdgeInsets(top: padding, leading: 0, bottom: padding, trailing: 0)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    func generateGridLayout() -> UICollectionViewLayout {
        let padding: CGFloat = 20
        
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1/4)), subitem: item, count: 3)
        group.interItemSpacing = .fixed(padding)
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: padding, bottom: 0, trailing: padding)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = padding
        section.contentInsets = NSDirectionalEdgeInsets(top: padding, leading: 0, bottom: padding, trailing: 0)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    func fetchData() {
        var componetns = URLComponents(string: "https://sheets.googleapis.com/v4/spreadsheets/1e8gLI6Ft1qlawb7DWHUGPUQlkpDaV5wxkuJvNkWGGHE/values/Sheet1")!
        componetns.queryItems = [URLQueryItem(name: "key", value: "AIzaSyBPybXkT_7v-Fjzg9xDnCpEglBRM1QtiV4")]
        let request = URLRequest(url: componetns.url!)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let data = data {
                do {
                    let response = try JSONDecoder().decode(Response.self, from: data).values
                    
                    self.constructEntriesTree(from: response)
                    
                    DispatchQueue.main.async {
                        self.updateUI()
                    }
                } catch DecodingError.keyNotFound(let key, let context) {
                    Swift.print("could not find key \(key) in JSON: \(context.debugDescription)")
                } catch DecodingError.valueNotFound(let type, let context) {
                    Swift.print("could not find type \(type) in JSON: \(context.debugDescription)")
                } catch DecodingError.typeMismatch(let type, let context) {
                    Swift.print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
                } catch DecodingError.dataCorrupted(let context) {
                    Swift.print("data found to be corrupted in JSON: \(context.debugDescription)")
                } catch let error as NSError {
                    NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    func updateUI() {
        collectionView.reloadData()
    }
    
    func constructEntriesTree(from values: [[String]]) {
        for value in values {
            let entry = Entry(itemID: UUID(uuidString: value[0])!, parentItemID: UUID(uuidString: value[1]), itemType: value[2] == "f" ? .file : .directory, itemName: value[3])
            entries.append(entry)
        }
        
        for entry in entries {
            if entry.parentItemID == nil {
                entriesTree[entry.itemID] = entry
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
            cell.update(with: entry)
        }
        
        return cell
    }

    // MARK: UICollectionViewDelegate

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
