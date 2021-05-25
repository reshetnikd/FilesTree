//
//  Entry.swift
//  FilesTree
//
//  Created by Dmitry Reshetnik on 13.05.2021.
//

//  Struct to discribe entry model. Each entry contains:
//      Item UUID.
//      Parent item UUID. If this field is empty - the item is located in the root directory.
//      Item type. F denotes a file, D denotes a directory
//      Item name


import Foundation

struct Entry: Codable, Comparable, Hashable {
    enum ItemType: String, Codable {
        case file
        case directory
    }
    
    let itemID: UUID
    let parentItemID: UUID?
    let itemType: ItemType
    let itemName: String
    
    func hasParentID(_ id: UUID) -> Bool {
        return self.parentItemID == id
    }
    
    static func < (lhs: Entry, rhs: Entry) -> Bool {
        switch (lhs.itemType, rhs.itemType) {
            case (.directory, .file):
                return true
            case (.file, .directory):
                return false
            case (.directory, .directory), (.file, .file):
                return lhs.itemName.lowercased() < rhs.itemName.lowercased()
        }
    }
}
