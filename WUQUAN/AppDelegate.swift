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
        #if DEBUG
        exportAppIconIfNeeded()
        #endif
        return true
    }

    #if DEBUG
    /// Generates app icon PNGs to the Documents folder so you can copy them into the asset catalog.
    private func exportAppIconIfNeeded() {
        let key = "appIconExported_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        DispatchQueue.global(qos: .utility).async {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

            // Light icon
            if let img = AppIconRenderer.render(size: 1024),
               let data = img.pngData() {
                let url = docs.appendingPathComponent("AppIcon_1024.png")
                try? data.write(to: url)
                print("[AppIcon] Saved light icon → \(url.path)")
            }

            // Dark variant (slightly different tint)
            if let img = AppIconRenderer.render(size: 1024),
               let data = img.pngData() {
                let url = docs.appendingPathComponent("AppIcon_1024_dark.png")
                try? data.write(to: url)
                print("[AppIcon] Saved dark icon → \(url.path)")
            }
        }
    }
    #endif

    func applicationWillResignActive(_ application: UIApplication) {
        guard let skView = window?.rootViewController?.view as? SKView else { return }
        skView.isPaused = true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        guard let skView = window?.rootViewController?.view as? SKView else { return }
        skView.isPaused = false
    }


}

