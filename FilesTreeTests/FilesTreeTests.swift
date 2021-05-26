//
//  FilesTreeTests.swift
//  FilesTreeTests
//
//  Created by Dmitry Reshetnik on 25.05.2021.
//

import XCTest
@testable import FilesTree

class FilesTreeTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        let entry = Entry(itemID: UUID(), parentItemID: nil, itemType: .directory, itemName: "Root")
        
        var context = Array(repeating: Entry(itemID: UUID(), parentItemID: entry.itemID, itemType: Bool.random() ? .directory : .file, itemName: "Untitled"), count: 50)
        
        measure {
            // Put the code you want to measure the time of here.
            context = Array(Set(context).subtracting(EntriesCollectionViewController().extractSubentires(from: context, with: entry.itemID)))
//            context = context.filter { !EntriesCollectionViewController(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: UICollectionLayoutListConfiguration(appearance: .insetGrouped))).extractSubentires(from: context, with: entry.itemID).contains($0) }
        }
    }

}
