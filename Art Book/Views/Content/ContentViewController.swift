//
//  ContentViewController.swift
//  Art Book
//
//  Created by xjbeta on 2018/10/1.
//  Copyright © 2018 xjbeta. All rights reserved.
//

import Cocoa
import CollectionView
import Quartz

class ContentViewController: NSViewController {

    @IBOutlet var collectionViewMenu: NSMenu!
    @IBOutlet weak var collectionView: CollectionView!
    @IBOutlet weak var tabView: NSTabView!
    
    @IBOutlet weak var applicationListMenu: NSMenu!
    
// MARK: - Menu Actions
    @IBAction func open(_ sender: Any) {
        guard let url = collectionViewSelectedUrl() else { return }
        NSWorkspace.shared.openFile(url.path)
    }
    
    @IBAction func openWithPreview(_ sender: Any) {
        guard let url = collectionViewSelectedUrl() else { return }
        NSWorkspace.shared.openFile(url.path, withApplication: "Preview.app")
    }
    
    @IBAction func moveToTrash(_ sender: Any) {
        guard let url = collectionViewSelectedUrl() else { return }
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
        } catch let error {
            print(error)
        }
        
    }
    
    @IBAction func showInFinder(_ sender: Any) {
        guard let url = collectionViewSelectedUrl() else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
// MARK: - Values
    var frameObserve: NSKeyValueObservation?
    var fileWatcher: FileWatcher?
    var fileNode: FileNode? = nil {
        didSet {
            filesObserver()
            fileNode?.childrenDics.count ?? 0 > 0 ? tabView.selectTabViewItem(at: 0) : tabView.selectTabViewItem(at: 1)
        }
    }
    
    let useCollectionView = true
    var baseWidth: CGFloat = 160
    var itemSizeScale: CGFloat = 1
    
    var viewMode: ViewMode = .column
    
    var layout: CollectionViewLayout {
        get {
            switch viewMode {
            case .column:
                let layout = CollectionViewColumnLayout()
                layout.layoutStrategy = .shortestFirst
                return layout
            case .flow:
                let layout = CollectionViewFlowLayout()
                layout.defaultRowTransform = .center
                return layout
            case .list:
                let layout = CollectionViewListLayout()
                layout.interitemSpacing = 20
                return layout
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = self.layout
        updateScale(layout)
        collectionView.collectionViewLayout = layout
        collectionView.allowsMultipleSelection = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.menu = collectionViewMenu
        
        frameObserve = collectionView.observe(\.frame) { view, _ in
            if view.collectionViewLayout is CollectionViewColumnLayout {
                self.updateScale(self.collectionView.collectionViewLayout)
                self.collectionView.reloadLayout(false, scrollPosition: .nearest)
            }
        }

        ImageItemCell.register(in: collectionView)
        
        NotificationCenter.default.addObserver(forName: .sidebarSelectionDidChange, object: nil, queue: .main) {
            if let userInfo = $0.userInfo as? [String: FileNode],
                let node = userInfo["node"] {
                self.fileNode = node
                ImageCache.shared.cleanDics()
                self.collectionView.reloadData()
                self.reloadPreviewPanel()
            }
        }
        
        NotificationCenter.default.addObserver(forName: .viewModeDidChange, object: nil, queue: .main) {
            if let userInfo = $0.userInfo as? [String: ViewMode],
                let viewMode = userInfo["viewMode"] {
                self.viewMode = viewMode
                let layout = self.layout
                self.updateScale(layout)
                self.collectionView.collectionViewLayout = layout
                self.collectionView.reloadLayout(true, scrollPosition: .nearest)
                self.reloadPreviewPanel()
            }
        }
        
        NotificationCenter.default.addObserver(forName: .scaleDidChange, object: nil, queue: .main) { _ in
            self.updateScale(self.collectionView.collectionViewLayout)
            self.collectionView.reloadLayout(false, scrollPosition: .nearest)
        }
        
        // check scrollView Magnification limit
//        NotificationCenter.default.addObserver(forName: NSScrollView.didEndLiveMagnifyNotification, object: nil, queue: .main) { _ in
//            guard let scrollView = self.scrollView else { return }
//            if scrollView.magnification < scrollView.minMagnification {
//                scrollView.setMagnification(scrollView.minMagnification, centeredAt: NSZeroPoint)
//            } else if scrollView.magnification > scrollView.maxMagnification {
//                scrollView.setMagnification(scrollView.maxMagnification, centeredAt: NSZeroPoint)
//            } else {
//
//                let size = self.imageBrowser.cellSize()
//
//                Log(self.imageBrowser.zoomValue())
//                self.imageBrowser.setZoomValue(2)
//
////                std::exp(magnification)
//                self.imageBrowser.needsDisplay = true
//
//                Log(self.imageBrowser.frame)
//                self.imageBrowser.setFrameSize(self.scrollView!.frame.size)
//                Log(self.imageBrowser.frame)
//
////                guard !self.singleMode else { return }
////                self.fileCollectionView.visibleItems().forEach { item in
////                    guard let coverViewItem = item as? CoverViewItem else {
////                        return
////                    }
////                    coverViewItem.updateImage(magnification: scrol#imageLiteral(resourceName: "02_001.jpg")lView.magnification)
////                }
//            }
//        }
    }
    
    func updateScale(_ layout: CollectionViewLayout) {
        let scale = CGFloat(Preferences.shared.scales(for: viewMode))
        let width = baseWidth * CGFloat(scale + 0.2) * 2.5

        if let l = layout as? CollectionViewColumnLayout {
            l.columnCount = Int(collectionView.frame.width / baseWidth / (1 + scale))
        } else if let l = layout as? CollectionViewFlowLayout {
            l.defaultItemStyle = .flow(NSSize(width: width, height: width))
        } else if let l = layout as? CollectionViewListLayout {
            let width = self.collectionView.frame.width * (0.5 - scale / 2) / 2
            l.sectionInsets = NSEdgeInsets(top: 0, left: width, bottom: 0, right: width)
        }
    }
    
    func filesObserver() {
        guard let path = fileNode?.url?.path else { return }
        fileWatcher?.stop()
        fileWatcher = nil
        fileWatcher = FileWatcher([path]) { [weak self] event in
            // check is hidden url
            let url = URL(fileURLWithPath: event.path)
            guard !url.lastPathComponent.starts(with: ".") else { return }
            
            // check is child of observed folder
            guard url.path.isChildItem(of: path) else { return }
            
            // check url is Directory
            // The doesn't exist file will skip Directory checker
            var isDirectory = ObjCBool(false)
            let exists = FileManager.default.fileExists(atPath: event.path, isDirectory: &isDirectory)
            guard !isDirectory.boolValue else { return }
            
            if !exists {
                // deleted file/path
                guard let index = self?.fileNode?.childrenImages.enumerated().filter ({
                    $0.element.name == url.lastPathComponent
                }).map ({
                    $0.offset
                }).first else { return }
                self?.fileNode?.childrenImages.remove(at: index)
                self?.collectionView.deleteItems(at: [IndexPath(item: index, section: 0)], animated: true)
                return
            }
            
            if event.fileCreated || event.fileRenamed {
                
                guard let index = self?.fileNode?.childrenImages.enumerated().filter ({
                    $0.element.name == url.lastPathComponent
                }).map ({
                    $0.offset
                }).first else {
                    let newNode = FileNode(url: url)
                    if let index = self?.fileNode?.childrenImages.firstIndex(where: { $0.name > newNode.name }) {
                        self?.fileNode?.childrenImages.insert(newNode, at: index)
                        self?.collectionView.insertItems(at: [IndexPath(item: index, section: 0)], animated: true)
                    }
                    return
                }
                
                let indexPath = IndexPath(item: index, section: 0)
                self?.collectionView.reloadItems(at: [indexPath], animated: false)
                if let cell = self?.collectionView.cellForItem(at: indexPath) as? ImageItemCell {
                    cell.initImageView(true)
                }
            } else if event.fileModified {
                Log("fileModified")
            } else if event.fileRemoved {
                Log("fileRemoved")
            } else if event.dirRemoved || event.dirModified || event.dirChange || event.dirCreated || event.dirRenamed {
                return
            } else {
                Log("Unknown file watcher event.")
                Log(event.description)
            }
        }
        
        fileWatcher?.start()
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 49: // Space
            togglePreviewPanel()
        default:
            return
        }
    }
    
    private func togglePreviewPanel() {
        guard let panel = QLPreviewPanel.shared() else { return }
        if QLPreviewPanel.sharedPreviewPanelExists() && panel.isVisible {
            panel.orderOut(nil)
        } else {
            guard collectionView.indexPathsForSelectedItems.count > 0 else { return }
            panel.orderFront(nil)
            panel.center()
        }
    }
    
    private func reloadPreviewPanel() {
        guard let panel = QLPreviewPanel.shared() else { return }
        if QLPreviewPanel.sharedPreviewPanelExists() && panel.isVisible {
            panel.reloadData()
        }
    }
    
    
    var markEvent: NSEvent? = nil
    
    deinit {
        frameObserve?.invalidate()
        fileWatcher?.stop()
        fileWatcher = nil
    }
}




//#pragma mark search
//
///*
// this code filters the "images" array depending on the current search field value. All items that are filtered-out are kept in the
// "filteredOutImages" array (and corresponding indexes are kept in "filteredOutIndexes" in order to restore these indexes when the search field is cleared
// */
//
//- (BOOL) keyword:(NSString *) aKeyword matchSearch:(NSString *) search
//{
//    NSRange r = [aKeyword rangeOfString:search options:NSCaseInsensitiveSearch];
//    return (r.length>0 && r.location>=0);
//    }
//
//    - (IBAction) searchFieldChanged:(id) sender
//{
//    if(filteredOutImages == nil){
//        //first time we use the search field
//        filteredOutImages = [[NSMutableArray alloc] init];
//        filteredOutIndexes = [[NSMutableIndexSet alloc] init];
//    }
//    else{
//        //restore the original datasource, and restore the initial ordering if possible
//
//        NSUInteger lastIndex = [filteredOutIndexes lastIndex];
//        if(lastIndex >= [images count] + [filteredOutImages count]){
//            //can't restore previous indexes, just insert filtered items at the beginning
//            [images insertObjects:filteredOutImages atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [filteredOutImages count])]];
//        }
//        else
//        [images insertObjects:filteredOutImages atIndexes:filteredOutIndexes];
//
//        [filteredOutImages removeAllObjects];
//        [filteredOutIndexes removeAllIndexes];
//    }
//
//    //add filtered images to the filteredOut array
//    NSString *searchString = [sender stringValue];
//
//    if(searchString != nil && [searchString length] > 0){
//        int i, n;
//
//        n = [images count];
//
//        for(i=0; i<n; i++){
//            MyImageObject *anItem = [images objectAtIndex:i];
//
//            if([self keyword:[anItem imageTitle] matchSearch:searchString] == NO){
//                [filteredOutImages addObject:anItem];
//                [filteredOutIndexes addIndex:i];
//            }
//        }
//    }
//
//    //remove filtered-out images from the datasource array
//    [images removeObjectsInArray:filteredOutImages];
//
//    //reflect changes in the browser
//    [imageBrowser reloadData];
//}


// MARK: - Collection View Delegate & DataSource

extension ContentViewController: CollectionViewDelegate, CollectionViewDataSource, CollectionViewDelegateColumnLayout, CollectionViewDelegateListLayout {
    func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        let cell = ImageItemCell.deque(for: indexPath, in: collectionView) as! ImageItemCell
        guard let node = fileNode?.childrenImages[indexPath.item] else { return cell }
        cell.initNode(node)
        return cell
    }

    func numberOfSections(in collectionView: CollectionView) -> Int {
        if let c = fileNode?.childrenImages.count, c > 0 {
            return 1
        }
        return 0
    }
    
    
    func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return fileNode?.childrenImages.count ?? 0
    }
    
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, heightForItemAt indexPath: IndexPath) -> CGFloat {
        guard let node = fileNode?.childrenImages[indexPath.item] else { return 0 }
        
        guard let width = imageViewWidth() else { return 0 }
        return imageViewHeight(width, node: node)
    }
    
    func collectionView(_ collectionView: CollectionView, willDisplayCell cell: CollectionViewCell, forItemAt indexPath: IndexPath) {
        let visibleIndexs = collectionView.indexPathsForVisibleItems.map { $0._item }
        guard visibleIndexs.count > 0 else { return }
        let preloading = true
        guard preloading else { return }

        let preloadCount = 5

        let newItem = indexPath._item
        guard let min = visibleIndexs.min(),
            let max = visibleIndexs.max(),
            let nodes = fileNode?.childrenImages,
            let width = imageViewWidth() else { return }
        if newItem < min {
            // Preloading forward -
            let s = newItem - preloadCount + 1 >= 0 ? newItem - preloadCount + 1 : 0
            let e = newItem < nodes.count ? newItem : nodes.count - 1
            let items = nodes[s...e]
            print(items.map({ $0.name }))
            
            
            items.forEach {
                ImageCache.shared.requestPreviewImage($0, width)
            }
        } else if newItem > max {
            // Preloading backwards +
            let s = newItem < nodes.count ? newItem : nodes.count - 1
            let e = (newItem + preloadCount) < nodes.count ? (newItem + preloadCount) : nodes.count - 1
            let items = nodes[s...e]
            print(items.map({ $0.name }))
            items.forEach {
                ImageCache.shared.requestPreviewImage($0, width)
            }
        } else {
            // Preloading middle ?
        }
    }
    
    func collectionView(_ collectionView: CollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        reloadPreviewPanel()
    }
    
    func collectionViewLayoutAnchor(_ collectionView: CollectionView) -> IndexPath? {
        if let i = collectionView.indexPathsForSelectedItems.first {
            return i
        }
        let indexPaths = collectionView.indexPathsForVisibleItems.sorted()
        let index = indexPaths.count / 2
        return indexPaths.first?._item == 0 ? indexPaths.first : indexPaths[safe: index]
    }
    
    func imageViewWidth() -> CGFloat? {
        if let l = collectionView.collectionViewLayout as? CollectionViewColumnLayout {
            return (collectionView.frame.width
                - CGFloat(l.columnCount - 1) * l.interitemSpacing
                - l.sectionInset.left
                - l.sectionInset.right) / CGFloat(l.columnCount)
                - 16
            
        } else if let l = collectionView.collectionViewLayout as? CollectionViewListLayout {
            return (collectionView.frame.width
                - l.sectionInsets.left
                - l.sectionInsets.right)
                - 16
        } else if let l = collectionView.collectionViewLayout as? CollectionViewFlowLayout {
            switch l.defaultItemStyle {
            case .flow(let size):
                return size.width - 16
            default:
                break
            }
        }
        return nil
    }
    
    func imageViewHeight(_ width: CGFloat, node: FileNode) -> CGFloat {
        guard let imageRatio = node.imageRatio else { return 0 }
        var height = width / imageRatio
        
        let textFiled = NSTextFieldCell()
        textFiled.font = NSFont.systemFont(ofSize: 13)
        textFiled.stringValue = node.url?.lastPathComponent ?? ""
        let textHeight = textFiled.cellSize(forBounds: NSRect(x: 0, y: 0, width: width, height: 32)).height

        height += textHeight
        height += 22
        
        return height
    }
    
    func collectionViewSelectedUrl() -> URL? {
        guard let indexPath = collectionView.indexPathForHighlightedItem,
            let url = fileNode?.childrenImages[indexPath.item].url else { return nil }
        return url
    }
}

// MARK: - CollectionView PreViewPanel

extension ContentViewController: QLPreviewPanelDelegate, QLPreviewPanelDataSource {
    
    override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
        return collectionView.indexPathsForSelectedItems.count > 0
    }
    override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
        panel.delegate = self
        panel.dataSource = self
        markEvent = nil
    }
    override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
        markEvent = nil
    }
    
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return collectionView.indexPathsForSelectedItems.count
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        guard let indexPath = collectionView.indexPathsForSelectedItems.first,
            let url = fileNode?.childrenImages[indexPath.item].url else {
            return nil
        }
        return url as QLPreviewItem
    }
    
    
    func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        if markEvent == nil {
            markEvent = event
        } else {
            markEvent = nil
            return false
        }
        
        switch event.keyCode {
        case 123, 124, 125, 126: // Left, Right, Up, Down
            collectionView.keyDown(with: event)
            QLPreviewPanel.shared().reloadData()
        default:
            return false
        }
        return true
    }
}


// MARK: - CollectionView Menu Delegate

extension ContentViewController: NSMenuItemValidation, NSMenuDelegate {
    public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(moveToTrash) {
            return false
        }
        return true
    }
    
    public func menuWillOpen(_ menu: NSMenu) {
        guard menu == applicationListMenu else { return }
        menu.removeAllItems()
        
        guard let url = collectionViewSelectedUrl() else {
                menu.addItem(NSMenuItem(title: "None", action: nil, keyEquivalent: ""))
                return
        }
        
        // Default App
        if let defaultApp = LSCopyDefaultApplicationURLForURL(url as CFURL, .all, nil)?.takeRetainedValue() as URL? {
            let item = menuItem(for: defaultApp)
            item.title += " (Default)"
            menu.addItem(item)
        } else {
            menu.addItem(NSMenuItem(title: "None", action: nil, keyEquivalent: ""))
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Other App
        if var apps = LSCopyApplicationURLsForURL(url as CFURL, .all)?.takeRetainedValue() as? [URL] {
            apps.sort {
                return $0.lastPathComponent.compare($1.lastPathComponent, options: .numeric) == .orderedAscending
            }
            apps.forEach {
                menu.addItem(menuItem(for: $0))
            }
        }
    }
    
    func menuItem(for url: URL) -> NSMenuItem {
        let item = NSMenuItem(title: url.lastPathComponent, action: nil, keyEquivalent: "")
        let image = NSWorkspace.shared.icon(forFile: url.path)
        image.size = NSSize(width: 17, height: 17)
        item.image = image
        item.action = #selector(openWithApplications)
        return item
    }
    
    @objc func openWithApplications(_ sender: NSMenuItem) {
        guard let url = collectionViewSelectedUrl() else { return }
        var appName = sender.title
        let endStr = " (Default)"
        if appName.hasSuffix(endStr) {
            let prefixIndex = appName.index(appName.startIndex, offsetBy: appName.count - endStr.count)
            appName = String(appName[..<prefixIndex])
        }
        
        NSWorkspace.shared.openFile(url.path, withApplication: appName, andDeactivate: true)
    }
    
}
