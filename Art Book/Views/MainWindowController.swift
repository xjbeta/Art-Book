//
//  MainWindowController.swift
//  Art Book
//
//  Created by xjbeta on 2018/9/30.
//  Copyright © 2018 xjbeta. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {

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
    
    @IBOutlet weak var forwardBackWardSegmentedControl: NSSegmentedControl!
    @IBAction func forwardBackward(_ sender: NSSegmentedControl) {
        var index = -1
        switch sender.selectedSegment {
        case 0:
            // backward
            index = historys.current - 1
        case 1:
            // forward
            index = historys.current + 1
        default:
            return
        }
        guard let item = historys.history[safe: index] else {
            return
        }
        historys.current = index
        
        NotificationCenter.default.post(name: .sidebarSelectionDidChange, object: nil, userInfo: ["node": item, "saveToHistorys": false])
        updateForwardBackwardState()
    }
    
    var historys = (history: [FileNode](), current: -1)
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.isMovableByWindowBackground = true
        window?.backgroundColor = NSColor.controlBackgroundColor
        modeSegmentedControl.selectSegment(withTag: 0)
        scaleSlider.doubleValue = Preferences.shared.scales(for: .column)
        
        NotificationCenter.default.addObserver(forName: .sidebarSelectionDidChange, object: nil, queue: .main) { [weak self] in
            guard let userInfo = $0.userInfo as? [String: Any],
                let node = userInfo["node"] as? FileNode,
                userInfo["saveToHistorys"] == nil else {
                    return
            }
            guard let historys = self?.historys else { return }
            
            if historys.current != historys.history.count - 1 {
                let k = historys.history.count - historys.current - 1
                self?.historys.history.removeLast(k)
            }
            
            self?.historys.history.append(node)
            self?.historys.current = (self?.historys.history.count ?? 0) - 1
            
            self?.updateForwardBackwardState()
        }
        updateForwardBackwardState()
    }
    
    func updateForwardBackwardState() {
        guard let control = forwardBackWardSegmentedControl,
            control.segmentCount == 2 else { return }
        control.setEnabled(historys.current != (historys.history.count - 1), forSegment: 1)
        control.setEnabled(historys.current > 0, forSegment: 0)
    }
}
