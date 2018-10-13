//
//  FileNode.swift
//  Art Book
//
//  Created by xjbeta on 2018/9/30.
//  Copyright © 2018 xjbeta. All rights reserved.
//

import Cocoa
//import Kingfisher
import Quartz

@objc(FileNode)
class FileNode: NSObject {

    @objc dynamic var name: String = ""
    @objc dynamic var childrenDics: [FileNode] {
        get {
            guard let url = url else { return [] }
            do {
                let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)
                    .filter { url -> Bool in
                        return try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false
                }
                return urls.map {
                    FileNode.init(url: $0)
                }
            } catch let error {
                print(error)
            }
            return []
        }
    }
    private var savedChildrenImages: [FileNode] = []
    
    var childrenImages: [FileNode] {
        get {
            guard savedChildrenImages.count == 0 else { return savedChildrenImages }
            guard let url = url else { return [] }
            do {
                let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

                    .filter {
                        $0.isImage()
                    }.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
                let nodes = urls.map {
                    FileNode(url: $0)
                }
                savedChildrenImages = nodes
                return nodes
            } catch let error {
                print(error)
            }
            return []
        }
    }
    
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
        
        DispatchQueue.global().async {
            let _ = self.imageRatio
//            let _ = self.childrenImages
        }
    }
    
    override func imageRepresentationType() -> String! {
        return IKImageBrowserPathRepresentationType
    }
    
    override func imageRepresentation() -> Any! {
        return url?.path
    }
    
    override func imageUID() -> String! {
        return url?.path
    }
    
    override func imageTitle() -> String! {
        return url?.lastPathComponent
    }
}

extension URL {
    func isImage() -> Bool {
        let fileExtension = self.pathExtension
        let fileUTI:Unmanaged<CFString>! = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)
        return UTTypeConformsTo(fileUTI.takeUnretainedValue(), kUTTypeImage)
    }
}
