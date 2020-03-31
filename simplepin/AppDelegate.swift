//
//  AppDelegate.swift
//  simplepin
//
//  Created by Mathias Lindholm on 29.2.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let defaults = UserDefaults(suiteName: "group.ml.simplepin")!
    var window: UIWindow?
    var storyboard: UIStoryboard?
    var navigation: UINavigationController?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        migrateUserDefaultsToAppGroups()

        self.window?.tintColor = Colors.Blue
        UINavigationBar.appearance().tintColor = Colors.Blue
        UITabBar.appearance().tintColor = Colors.Blue

        self.storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        if defaults.string(forKey: "userToken") == nil {
            self.showLoginScreen(animated: false)
        }

        Fabric.with([Crashlytics.self])
        return true
    }
    func showLoginScreen(animated: Bool) {
        self.storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "login") {
            self.window?.makeKeyAndVisible()
            vc.modalPresentationStyle = .overFullScreen
            self.window?.rootViewController?.present(vc, animated: animated, completion: nil)
        }
    }

    func logOut() {
        let appDomain = Bundle.main.bundleIdentifier!
        let root = self.window?.rootViewController as! UINavigationController

        if let vc = root.topViewController as? BookmarksTableViewController {
            vc.bookmarksArray.removeAll()
            vc.filteredBookmarks.removeAll()
            vc.tableView.reloadData()
        }

        UserDefaults.standard.removePersistentDomain(forName: appDomain)
        for key in defaults.dictionaryRepresentation() {
            defaults.removeObject(forKey: key.0)
        }
        Answers.logCustomEvent(withName: "Log Out", customAttributes: nil)
        self.showLoginScreen(animated: true)
    }
}

enum UIUserInterfaceIdiom : Int {
    case Unspecified

    case Phone // iPhone and iPod touch style UI
    case Pad // iPad style UI
}
