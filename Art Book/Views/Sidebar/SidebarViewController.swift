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
    lazy var selectPanel = NSOpenPanel()
    
    @IBOutlet weak var sidebarOutlineView: NSOutlineView!
    @IBOutlet weak var addFolder: NSButton!
    @IBAction func addFolder(_ sender: NSButton) {
        selectPanel.allowsMultipleSelection = false
        selectPanel.canChooseDirectories = true
        selectPanel.canChooseFiles = false
        selectPanel.prompt = "Add"
        guard let window = self.view.window else { return }
        selectPanel.beginSheetModal(for: window) {
            guard $0 == .OK, let url = self.selectPanel.url else { return }
            Preferences.shared.addFavourite(url)
            self.initNodes()
        }
    }
    
    @objc dynamic var fileNodes: [FileNode] = []
    var fileWatcher: FileWatcher?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initAddFolder()
        initNodes()
        filesObserver()
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
        fileNodes = []
        let homes = FileNode(name: "Homes", true)
        fileNodes.append(homes)
        
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
        guard Preferences.shared.favourites.count > 0 else { return }
        let favourites = FileNode(name: "Favourites", true)
        fileNodes.append(favourites)
        
        Preferences.shared.favourites.forEach {
            let re = $0.startAccessingSecurityScopedResource()
            print("startAccessingSecurityScopedResource \(re)")
            fileNodes.append(FileNode(url: $0))
        }
    }
    
    
    func filesObserver() {
        let paths = fileNodes.compactMap {
            $0.url?.path
        }
        fileWatcher?.stop()
        fileWatcher = nil
        fileWatcher = FileWatcher(paths) { [weak self] event in
            // check is hidden url
            let url = URL(fileURLWithPath: event.path)
            guard !url.lastPathComponent.starts(with: ".") else { return }
            
            // check url is Directory
            // The doesn't exist file will skip Directory checker
            var isDirectory = ObjCBool(true)
            let exists = FileManager.default.fileExists(atPath: event.path, isDirectory: &isDirectory)
            guard isDirectory.boolValue else { return }
            
            guard let rootNodes = self?.fileNodes.filter({ node -> Bool in
                guard let url = node.url else { return false }
                return event.path.isChildPath(of: url.path)
            }) else { return }
            rootNodes.forEach { node in
                var pathComponents = event.path.pathComponents
                let title = pathComponents.last ?? ""
                
                pathComponents.removeSubrange(0 ..< node.url!.pathComponents.count)
                pathComponents = Array(pathComponents.dropLast())
                var currentNode = node
                while !pathComponents.isEmpty {
                    guard let title = pathComponents.first,
                        let node = currentNode.getChild(title) else {
                        pathComponents.removeAll()
                        return
                    }
                    pathComponents.removeFirst()
                    currentNode = node
                }
                
                // finded parent directory node -> currentNode
                
                if !exists {
                    // deleted file/path
                    guard let index = currentNode.childrenDics.enumerated().filter ({
                        $0.element.name == title
                        }).map ({
                            $0.offset
                        }).first else { return }
                    currentNode.childrenDics.remove(at: index)
                    return
                }
                
                if event.dirCreated || event.dirRenamed {
                    let newNode = FileNode(url: url)
                    if let index = currentNode.childrenDics.index(where: { $0.name > newNode.name }) {
                        currentNode.childrenDics.insert(newNode, at: index)
                    }
                } else if event.dirModified {
                    print("dirModified")
                    
                } else if event.dirRemoved {
                    print("dirRemoved")
                    
                } else if event.fileRemoved || event.fileModified || event.fileChange || event.fileCreated || event.fileRenamed {
                    return
                } else {
                    print("Unknown file watcher event.")
                    print(event.description)
                }
                
                
            }
        }
        
        fileWatcher?.start()
    }
    
    
    deinit {
        fileWatcher?.stop()
        fileWatcher = nil
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

extension SidebarViewController: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let item = (sidebarOutlineView.item(atRow: sidebarOutlineView.clickedRow) as? NSTreeNode)?.representedObject as? FileNode else {
                return false
        }
        if menuItem.action == #selector(showInFinder) {
            return true
        }
        
        if menuItem.action == #selector(removeFromSidebar) {
//            return fileNodes.contains(item) && item.
        }
        return true
    }
    
    @IBAction func showInFinder(_ sender: Any) {
        guard let item = (sidebarOutlineView.item(atRow: sidebarOutlineView.clickedRow) as? NSTreeNode)?.representedObject as? FileNode,
            let url = item.url else {
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    @IBAction func removeFromSidebar(_ sender: Any) {
        guard let item = (sidebarOutlineView.item(atRow: sidebarOutlineView.clickedRow) as? NSTreeNode)?.representedObject as? FileNode,
            let url = item.url else {
                return
        }
        url.stopAccessingSecurityScopedResource()
        Preferences.shared.removeFavourite(url)
        initNodes()
    }
    
}


extension String {
    var pathComponents: [String] {
        get {
            return (self.standardizingPath as NSString).pathComponents
        }
    }
    
    var standardizingPath: String {
        get {
            return (self as NSString).standardizingPath
        }
    }
    
    func isChildPath(of url: String) -> Bool {
        guard self.pathComponents.count > url.pathComponents.count else {
            return false
        }
        var t = self.pathComponents
        t.removeSubrange(url.pathComponents.count ..< self.pathComponents.count)
        return t == url.pathComponents
    }
}
