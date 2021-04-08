//
//  FileNode.swift
//  Art Book
//
//  Created by xjbeta on 2018/9/30.
//  Copyright © 2018 xjbeta. All rights reserved.
//

import Cocoa

@objc(FileNode)
class FileNode: NSObject {
    
    var id: String?

    @objc dynamic var name: String = ""
    @objc var childrenDics = [FileNode]()
    @objc dynamic var loading = false
    
    lazy var childrenImages: [FileNode] = {
        guard let url = url else { return [] }
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)
            var nodes = try urls.filter { url -> Bool in
                return !(try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false)
                }.filter {
                    $0.isImage()
                }.map {
                    FileNode(url: $0)
            }
            nodes.sort { $0.name < $1.name }
            return nodes
        } catch let error {
            Log(error)
        }
        return []
    }()
    
    var savedImageSource: CGImageSource?
    var imageSource: CGImageSource? {
        get {
            guard savedImageSource == nil else { return savedImageSource }
            
            guard let sourceURL = url,
                let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
                let _ = CGImageSourceGetType(imageSource) else { return nil }
            savedImageSource = imageSource
            return imageSource
        }
    }
    
    private var savedImageRatio: CGFloat?
    var imageRatio: CGFloat? {
        get {
            guard savedImageRatio == nil else { return savedImageRatio }
            guard let url = self.url,
                let date = url.fileModificationDate() else { return nil }
            let key = url.path + " - " + "\(date)"
            if let ratio = ImageCache.shared.ratio(forKey: key) {
                return ratio
            } else if let image = NSImageRep(contentsOf: url) {
                let imageSize = NSSize(width: image.pixelsWide, height: image.pixelsHigh)
                let ratio = imageSize.width / imageSize.height
                ImageCache.shared.setRatio(ratio, forKey: key)
                savedImageRatio = ratio
                return ratio
            }
            return nil
        }
    }
    
    
    var isHeader = false
    var url: URL?
    @objc dynamic var isLeaf: Bool {
        get {
            return childrenDics.isEmpty
//            return true
        }
    }
    
    init(name: String, _ isHeader: Bool = false) {
        self.name = name
        self.isHeader = isHeader
    }
    
    init(url: URL, id: String? = nil) {
        super.init()
        self.url = url
        name = url.lastPathComponent
        self.id = id
        loading = true
    }
    
    func initChildrenDics() {
        guard !isHeader,
              let url = url else { return }
        
        let ucc = url.pathComponents.count
        
        var paths = Task.shared.findAllFiles(url.path).map {
            NSString(string: $0).deletingLastPathComponent
        }.filter {
            $0.pathComponents.count >= ucc
        }
        
        paths = Array(Set(paths))
        
        paths.forEach {
            var pathComponents = $0.pathComponents
            pathComponents.removeSubrange(0..<ucc)
            
            var node = self
            var u = url
            
            while pathComponents.count != 0 {
                let name = pathComponents[0]
                u.appendPathComponent(name)
                
                if let n = node.childrenDics.first(where: { $0.name == name }) {
                    node = n
                } else {
                    let n = FileNode(name: name)
                    n.url = u
                    node.childrenDics.append(n)
                    node = n
                }
                
                pathComponents.removeFirst()
            }
        }
        
    }
    
    func getChild(_ name: String) -> FileNode? {
        return childrenDics.filter {
            $0.name == name
            }.first
    }
    
    func maxPixelSize(_ width: CGFloat) -> CGFloat {
        guard let scale = NSScreen.main?.backingScaleFactor,
            let ratio = imageRatio else {
            return 0
        }
        return CGFloat((Int(max(width, width / ratio) * scale / 100) + 1) * 100)
    }
    
    func cacheKey(_ width: CGFloat) -> String {
        let markPixelSize = maxPixelSize(width)
        guard let url = url, let date = url.fileModificationDate() else { return "" }
        var cacheKey = "\(url.absoluteString)"
        cacheKey += " - \(date)"
        cacheKey += " - \(markPixelSize)"
        return cacheKey
    }
}

extension URL {
    func isImage() -> Bool {
        let fileExtension = self.pathExtension
        let fileUTI:Unmanaged<CFString>! = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)
        return UTTypeConformsTo(fileUTI.takeUnretainedValue(), kUTTypeImage)
    }
    
    func fileModificationDate() -> Date? {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: path)
            return attr[FileAttributeKey.modificationDate] as? Date
        } catch {
            return nil
        }
    }
}
