//
//  SidebarViewController.swift
//  Art Book
//
//  Created by xjbeta on 2018/9/30.
//  Copyright © 2018 xjbeta. All rights reserved.
//

import Cocoa

class SidebarViewController: NSViewController {

    let fileManager = FileManager.default
    
    @IBOutlet weak var sidebarOutlineView: NSOutlineView!
    @IBOutlet weak var addFolder: NSButton!
    @IBAction func addFolder(_ sender: NSButton) {
    }
    @objc dynamic var fileNodes: [FileNode] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initAddFolder()
        initNodes()
        
        

        

    }
    
    func initAddFolder() {
        var image: NSImage? = nil
        
        if #available(OSX 10.12.2, *) {
            image = NSImage(named: NSImage.touchBarAddDetailTemplateName)
        } else {
            image = NSImage(named: NSImage.addTemplateName)
        }
        guard let i = image else {
            return
        }
        let s = 25 / i.size.height
        i.size = NSSize.init(width: i.size.width * s, height: i.size.height * s)
        
        addFolder.image = i
    }
    
    func initNodes() {
        let favourites = FileNode(name: "Favourites", true)
        fileNodes.append(favourites)
        
        do {
            var downloadsDirectory = try fileManager.url(for: .downloadsDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            downloadsDirectory.resolveSymlinksInPath()
            var picturesDirectory = try fileManager.url(for: .picturesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            picturesDirectory.resolveSymlinksInPath()
            
            fileNodes.append(FileNode(url: downloadsDirectory))
            fileNodes.append(FileNode(url: picturesDirectory))
            sidebarOutlineView.selectRowIndexes(IndexSet(integer: 1), byExtendingSelection: false)
//            NotificationCenter.default.post(name: .sidebarSelectionDidChange, object: nil, userInfo: ["node": FileNode(url: downloadsDirectory)])
        } catch let error {
            print(error)
        }
    }
    
}

extension SidebarViewController: NSOutlineViewDelegate, NSOutlineViewDataSource {
    
    
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = (item as? NSTreeNode)?.representedObject as? FileNode else {
            return nil
        }
        if node.isHeader {
            if let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("SidebarHeaderCell"), owner: self) as? NSTableCellView {
                view.textField?.stringValue = node.name
                
                return view
            }
        } else {
            if let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("SidebarDataCell"), owner: self) as? NSTableCellView {
                view.textField?.stringValue = node.name
                let icon = NSWorkspace.shared.icon(forFile: node.url?.path ?? "")
                view.imageView?.image = icon
                return view
            }
        }
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        guard let node = (item as? NSTreeNode)?.representedObject as? FileNode else {
            return 0
        }
        if node.isHeader {
            return 17
        } else {
            return 24
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        guard let node = (item as? NSTreeNode)?.representedObject as? FileNode else {
            return false
        }
        return !node.isHeader
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let item = (sidebarOutlineView.item(atRow: sidebarOutlineView.selectedRow) as? NSTreeNode)?.representedObject as? FileNode else {
            return
        }
        
        NotificationCenter.default.post(name: .sidebarSelectionDidChange, object: nil, userInfo: ["node": item])
    }
    
    
}
