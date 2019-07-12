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

    @objc dynamic var name: String = ""
    @objc dynamic lazy var childrenDics: [FileNode] = {
        guard let url = url else { return [] }
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)
            var nodes = try urls.filter { url -> Bool in
                return try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false
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
    
    init(url: URL) {
        super.init()
        self.url = url
        name = url.lastPathComponent
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
