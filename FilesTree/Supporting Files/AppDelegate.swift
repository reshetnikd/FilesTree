//
//  AppDelegate.swift
//  FilesTree
//
//  Created by Dmitry Reshetnik on 13.05.2021.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST

@main
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    var window: UIWindow?
    
    @available(iOS 9.0, *)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance().handle(url)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GIDSignIn.sharedInstance().handle(url)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
                print("The user has not signed in before or they have since signed out.")
            } else {
                print("\(error.localizedDescription)")
            }
            return
        }
        
        // Request additional scopes.
        if !user.grantedScopes.contains(where: { $0 as! String == kGTLRAuthScopeSheetsSpreadsheets }) {
            var currentScopes = GIDSignIn.sharedInstance().scopes
            currentScopes?.append(kGTLRAuthScopeSheetsSpreadsheets)
            
            GIDSignIn.sharedInstance().scopes = currentScopes
            // Set loginHint to skip the account chooser.
            GIDSignIn.sharedInstance().loginHint = user.profile.email
            GIDSignIn.sharedInstance().signIn()
        } else {
            App.sharedInstance.state = .authorized
            NotificationCenter.default.post(name: App.stateAuthorizedNotidication, object: nil)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!,
              withError error: Error!) {
        App.sharedInstance.state = .unauthorized
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let rootViewController = EntriesCollectionViewController()
        
        window = UIWindow()
        window?.rootViewController = UINavigationController(rootViewController: rootViewController)
        window?.makeKeyAndVisible()
        
        // Initialize sign-in with Google.
        GIDSignIn.sharedInstance().clientID = "913111204097-6oa0ga437ujrv30jnogs0hbqk60k8rsa.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().presentingViewController = window?.rootViewController
        
        // Automatically sign in the user.
        GIDSignIn.sharedInstance().restorePreviousSignIn()
        
        return true
    }


}

