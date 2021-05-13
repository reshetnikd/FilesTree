//
//  EntryCollectionViewCell.swift
//  FilesTree
//
//  Created by Dmitry Reshetnik on 13.05.2021.
//

import UIKit

class EntryCollectionViewCell: UICollectionViewCell {
    @IBOutlet var itemTypeImageView: UIImageView!
    @IBOutlet var itemNameLabel: UILabel!
    
    func update(with entry: Entry) {
        itemTypeImageView.image = UIImage(systemName: entry.itemType == .directory ? "folder" : "doc.richtext")
        itemNameLabel.text = entry.itemName
    }
}
