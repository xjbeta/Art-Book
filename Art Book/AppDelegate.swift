//
//  AppDelegate.swift
//  Art Book
//
//  Created by xjbeta on 2018/9/30.
//  Copyright © 2018 xjbeta. All rights reserved.
//

import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {


    lazy var logUrl: URL? = {
        do {
            let documentDirectoryPath = try FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            var log = documentDirectoryPath.appendingPathComponent("Logs").appendingPathComponent("ArtBook.log")
            return log
        } catch let error {
            Log(error)
            return nil
        }
    }()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let url = logUrl {
            try? FileManager.default.removeItem(at: url)
        }
        
        Log("App will finish launching")
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        Log("App Version \(version) (Build \(build))")
        Log("macOS " + ProcessInfo().operatingSystemVersionString)
        
        removeExpired()
        Preferences.shared.prepareUserDefaults()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        ImageCache.shared.saveRatios()
        removeExpired()
    }
    
    func removeExpired() {
        Log(ImageCache.shared.cacheSize())
        ImageCache.shared.removeExpired()
        Log(ImageCache.shared.cacheSize())
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                if window.className == "NSWindow" {
                    window.makeKeyAndOrderFront(self)
                }
            }
        }
        return true
    }
}
