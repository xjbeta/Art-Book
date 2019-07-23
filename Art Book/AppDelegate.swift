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


//extension AppDelegate: DevMateKitDelegate {
//
//    func setDevMate() {
//        #if DEBUG
//        DMKitDebugAddDevMateMenu()
//        #endif
//        //DevMate
//        if let url = logUrl {
//            DevMateKit.setupCustomLogFileURLs([url as NSURL])
//        }
//
//        DevMateKit.sendTrackingReport(nil, delegate: self)
//
//        DevMateKit.setupIssuesController(self, reportingUnhandledIssues: true)
//
//
//        if !string_check(nil).boolValue {
//            DevMateKit.setupTimeTrial(self, withTimeInterval: kDMTrialWeek)
//        }
//        NotificationCenter.default.addObserver(self, selector: #selector(activateApp), name: .activateApp, object: nil)
//
//    }
//
//    @objc func feedbackController(_ controller: DMFeedbackController, parentWindowFor mode: DMFeedbackMode) -> NSWindow {
//        return mainWindowController.window!
//    }
//
//    @objc func activationController(_ controller: DMActivationController, parentWindowFor mode: DMActivationMode) -> NSWindow? {
//        return mainWindowController.window
//    }
//
//    @objc private func activationController(_ controller: DMActivationController!, shouldShowDialogFor reason: DMShowDialogReason, withAdditionalInfo additionalInfo: [AnyHashable : Any]!, proposedActivationMode ioProposedMode: UnsafeMutablePointer<DMActivationMode>!, completionHandlerSetter handlerSetter: ((DMCompletionHandler?) -> Void)!) -> Bool {
//        ioProposedMode.pointee = .sheet
//        handlerSetter { _ in
//            ViewControllersManager.shared.showAria2cAlert()
//        }
//        return true
//    }
//
//    @objc func activateApp() {
//        // Swift does't work with macros, so check our Examples project on GitHub (https://github.com/DevMate/DevMateKit)
//        // to see how to create _my_secret_activation_check variable
//        if !string_check(nil).boolValue {
//            DevMateKit.runActivationDialog(self, in: .sheet)
//        } else if let window = mainWindowController.window,
//            let license = string_info()?.takeUnretainedValue() as? [String: AnyObject] {
//
//            let licenseAlert = NSAlert()
//            licenseAlert.messageText = NSLocalizedString("licenseInfo.messageText", comment: "")
//
//            licenseAlert.informativeText = "This product is licensed to:\n    email: \(license["email"] as? String ?? "")\n    activation id: \(license["activation_number"] as? String ?? "")"
//
//            licenseAlert.addButton(withTitle: NSLocalizedString("licenseInfo.okButton", comment: ""))
//            licenseAlert.addButton(withTitle: NSLocalizedString("licenseInfo.invalidateButton", comment: ""))
//
//
//            let warningAlert = NSAlert()
//            warningAlert.alertStyle = .critical
//            warningAlert.messageText = NSLocalizedString("licenseInfo.invalidateButton", comment: "")
//            warningAlert.informativeText = NSLocalizedString("licenseInfo.informativeText", comment: "")
//            warningAlert.addButton(withTitle: NSLocalizedString("licenseInfo.okButton", comment: ""))
//            warningAlert.addButton(withTitle: NSLocalizedString("licenseInfo.cancelButton", comment: ""))
//
//            DispatchQueue.main.async {
//                licenseAlert.beginSheetModal(for: window) {
//                    if $0 == .alertSecondButtonReturn {
//                        let response = warningAlert.runModal()
//                        if response == .alertFirstButtonReturn {
//                            InvalidateAppLicense()
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
