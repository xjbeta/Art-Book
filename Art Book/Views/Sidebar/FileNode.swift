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
            print(error)
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
            print(error)
        }
        return []
    }()
    
    private var savedImageRatio: CGFloat?
    var imageRatio: CGFloat? {
        get {
            guard savedImageRatio == nil else { return savedImageRatio }
            
            if let url = self.url,
                let image = NSImageRep(contentsOf: url) {
                let imageSize = NSSize(width: image.pixelsWide, height: image.pixelsHigh)
                let ratio = imageSize.width / imageSize.height
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
}

extension URL {
    func isImage() -> Bool {
        let fileExtension = self.pathExtension
        let fileUTI:Unmanaged<CFString>! = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)
        return UTTypeConformsTo(fileUTI.takeUnretainedValue(), kUTTypeImage)
    }
}
