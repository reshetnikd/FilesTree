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
    let accessoryImageView = UIImageView()
    let seperatorView = UIView()
    
    func update(with entry: Entry, for layout: Layout) {
        itemTypeImageView.image = UIImage(systemName: entry.itemType == .directory ? "folder" : "doc.richtext")
        itemNameLabel.text = entry.itemName
        
        if layout == .column {
            seperatorView.translatesAutoresizingMaskIntoConstraints = false
            seperatorView.backgroundColor = .lightGray
            contentView.addSubview(seperatorView)
            
            accessoryImageView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(accessoryImageView)
            
            let rtl = effectiveUserInterfaceLayoutDirection == .rightToLeft
            let chevronImageName = rtl ? "chevron.left" : "chevron.right"
            let chevronImage = UIImage(systemName: chevronImageName)
            accessoryImageView.image = chevronImage
            accessoryImageView.tintColor = UIColor.systemBlue
            
            let inset = CGFloat(5)
            NSLayoutConstraint.activate([
                accessoryImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                accessoryImageView.widthAnchor.constraint(equalToConstant: 13),
                accessoryImageView.heightAnchor.constraint(equalToConstant: 20),
                accessoryImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
                accessoryImageView.leadingAnchor.constraint(equalTo: itemNameLabel.trailingAnchor, constant: 8),
                
                seperatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
                seperatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                seperatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
                seperatorView.heightAnchor.constraint(equalToConstant: 0.5)
            ])
            
            if entry.itemType == .file {
                accessoryImageView.removeFromSuperview()
            }
        }
    }
}
