//
//  EntryCollectionViewCell.swift
//  FilesTree
//
//  Created by Dmitry Reshetnik on 13.05.2021.
//

import UIKit

class EntryCollectionViewCell: UICollectionViewCell {
    let itemTypeImageView = UIImageView()
    let itemNameLabel = UILabel()
    let accessoryImageView = UIImageView()
    let seperatorView = UIView()
    
    func update(with entry: Entry, for layout: Layout) {
        // Initial configuration of entry thumbnail.
        var configuration = UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: UIFont.systemFontSize))
    
        // Add imageView to superview.
        itemTypeImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(itemTypeImageView)
        
        // Add label to superview and set it text value.
        itemNameLabel.text = entry.itemName
        itemNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(itemNameLabel)
        
        
        if layout == .column {
            // Configure thumbnail appearance for column layout.
            configuration = entry.itemType == .directory ? UIImage.SymbolConfiguration(pointSize: 24, weight: .regular) : UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
            itemTypeImageView.image = UIImage(systemName: entry.itemType == .directory ? "folder" : "doc.richtext", withConfiguration: configuration)
            
            // Add separator line to superview that will be visible only in column layout.
            seperatorView.translatesAutoresizingMaskIntoConstraints = false
            seperatorView.backgroundColor = .lightGray
            contentView.addSubview(seperatorView)
            
            // Add accessory image to superview that will appear only with entry of directory type.
            accessoryImageView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(accessoryImageView)
            
            // Configure accessory image.
            let rtl = effectiveUserInterfaceLayoutDirection == .rightToLeft
            let chevronImageName = rtl ? "chevron.left" : "chevron.right"
            let chevronImage = UIImage(systemName: chevronImageName)
            accessoryImageView.image = chevronImage
            accessoryImageView.tintColor = UIColor.systemBlue
            
            // Add constraints to accomplish desired layout.
            let inset = CGFloat(5)
            let indent = CGFloat(8)
            NSLayoutConstraint.activate([
                itemTypeImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                itemTypeImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: indent),
                itemTypeImageView.widthAnchor.constraint(equalToConstant: itemTypeImageView.intrinsicContentSize.width),
                
                itemNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                itemNameLabel.leadingAnchor.constraint(equalTo: itemTypeImageView.trailingAnchor, constant: indent),
                
                accessoryImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                accessoryImageView.widthAnchor.constraint(equalToConstant: 13),
                accessoryImageView.heightAnchor.constraint(equalToConstant: 20),
                accessoryImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
                accessoryImageView.leadingAnchor.constraint(equalTo: itemNameLabel.trailingAnchor, constant: indent),
                
                seperatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
                seperatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                seperatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
                seperatorView.heightAnchor.constraint(equalToConstant: 0.5)
            ])
            
            if entry.itemType == .file {
                accessoryImageView.removeFromSuperview()
            }
        } else if layout == .grid {
            // Configure thumbnail appearance for grid layout.
            configuration = entry.itemType == .directory ? UIImage.SymbolConfiguration(pointSize: 64, weight: .medium) : UIImage.SymbolConfiguration(pointSize: 72, weight: .medium)
            itemTypeImageView.image = UIImage(systemName: entry.itemType == .directory ? "folder" : "doc.richtext", withConfiguration: configuration)
            itemNameLabel.numberOfLines = 2
            itemNameLabel.textAlignment = .center
            
            // Draw thin border that will be visible only in grid layout.
            contentView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.7).cgColor
            contentView.layer.cornerRadius = 10
            contentView.layer.borderWidth = 1
            
            // Add constraints to accomplish desired layout.
            NSLayoutConstraint.activate([
                itemTypeImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                itemTypeImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: entry.itemType == .directory ? 8 : 0),
                
                itemNameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                itemNameLabel.topAnchor.constraint(equalTo: itemTypeImageView.bottomAnchor, constant: 8),
                itemNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                itemNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            ])
        }
    }
}
