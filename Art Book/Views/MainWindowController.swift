//
//  MainWindowController.swift
//  Art Book
//
//  Created by xjbeta on 2018/9/30.
//  Copyright © 2018 xjbeta. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {

    @IBAction func sidebar(_ sender: Any) {
        if let view = window?.contentViewController as? NSSplitViewController {
            view.toggleSidebar(sender)
        }
        
    }
    
    @IBOutlet weak var modeSegmentedControl: NSSegmentedControl!
    @IBAction func viewMode(_ sender: NSSegmentedControl) {
        guard let viewMode = ViewMode(raw: sender.selectedSegment) else { return }
        scaleSlider.doubleValue = Preferences.shared.scales(for: viewMode)
        NotificationCenter.default.post(name: .viewModeDidChange, object: nil, userInfo: ["viewMode": viewMode])
    }
    
    @IBOutlet weak var scaleSlider: NSSlider!
    @IBAction func scaleSilder(_ sender: NSSlider) {
        guard let viewMode = ViewMode(raw: modeSegmentedControl.selectedSegment) else { return }
        Preferences.shared.setScales(sender.doubleValue, for: viewMode)
        NotificationCenter.default.post(name: .scaleDidChange, object: nil)
    }
    
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.isMovableByWindowBackground = true
        modeSegmentedControl.selectSegment(withTag: 0)
        scaleSlider.doubleValue = Preferences.shared.scales(for: .column)
        
    }

}


enum ViewMode: String {
    case column
    case flow
    case list
    
    init?(raw: Int) {
        switch raw {
        case 0: self = .column
        case 1: self = .flow
        case 2: self = .list
        default: self = .column
        }
    }
}
