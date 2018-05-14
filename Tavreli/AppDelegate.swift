//
//  AppDelegate.swift
//  Tavreli
//
//  Created by Maria Dagaeva on 26.04.2018.
//  Copyright © 2018 scipianne. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        if let viewController = application.windows[0].rootViewController as? GameViewController {
            if viewController.model.networkingEngine?.gameState != .gameStateDone {
                viewController.model.networkingEngine.sendGameEnd(localResult: .localPlayerLost)
            }
        }
    }

}
