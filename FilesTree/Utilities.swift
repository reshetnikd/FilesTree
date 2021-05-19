//
//  Utilities.swift
//  FilesTree
//
//  Created by Dmitry Reshetnik on 19.05.2021.
//

import Foundation

extension String {
    func madeUnique(withRespectTo otherStrings: [String]) -> String {
        var possiblyUnique = self
        var uniqueNumber = 1
        while otherStrings.contains(possiblyUnique) {
            possiblyUnique = self + " \(uniqueNumber)"
            uniqueNumber += 1
        }
        return possiblyUnique
    }
}
