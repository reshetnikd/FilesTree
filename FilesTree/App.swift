//
//  App.swift
//  FilesTree
//
//  Created by Dmitry Reshetnik on 17.05.2021.
//

import Foundation

class App {
    enum State: String {
        case authorized
        case unauthorized
    }
    
    static let sharedInstance = App()
    static let stateUpdatedNotification = Notification.Name("App.stateUpdated")
  
    var state: State = .unauthorized {
        didSet {
            NotificationCenter.default.post(name: App.stateUpdatedNotification, object: nil)
        }
    }
}
