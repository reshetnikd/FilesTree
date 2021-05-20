//
//  App.swift
//  FilesTree
//
//  Created by Dmitry Reshetnik on 17.05.2021.
//

//  Class to observe application state and providing entries store.

import Foundation

class App {
    enum State: String {
        case authorized
        case unauthorized
    }
    
    static let sharedInstance = App()
    static let stateUpdatedNotification = Notification.Name("App.stateUpdated")
    static let stateAuthorizedNotidication = Notification.Name("App.stateAuthorized")
  
    var entriesStore: [Entry] = []
    var state: State = .unauthorized {
        didSet {
            NotificationCenter.default.post(name: App.stateUpdatedNotification, object: nil)
        }
    }
}
