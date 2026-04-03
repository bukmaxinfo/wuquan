//
//  AppDelegate.swift
//  WUQUAN
//
//  Created by shuming li on 7/19/25.
//

import UIKit
import SpriteKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        guard let skView = window?.rootViewController?.view as? SKView else { return }
        skView.isPaused = true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        guard let skView = window?.rootViewController?.view as? SKView else { return }
        skView.isPaused = false
    }


}

