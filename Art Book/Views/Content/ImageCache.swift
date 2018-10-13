//
//  ImageCache.swift
//  Art Book
//
//  Created by xjbeta on 2018/10/13.
//  Copyright © 2018 xjbeta. All rights reserved.
//

import Cocoa
import Cache

class ImageCache: NSObject {
    static let cacheName = "Image Cache"
    
    static let storage: DiskStorage<Image> = {
        let config = DiskConfig(name: cacheName)
        
        let storage = try! DiskStorage<Image>(config: config, transformer: TransformerFactory.forImage())
        return storage
    }()
    
    static func image(forKey key: String) -> Image? {
        return try? ImageCache.storage.object(forKey: key)
    }
    
    static func setImage(_ image: Image, forKey key: String) {
        var expiry = Expiry.seconds(2 * 3600)
        if let widthStr = key.components(separatedBy: " - ").last,
            let width = Int(widthStr),
            width < 500 {
            expiry = .seconds(3600 * 24 * 15)
        }
        
        do {
            try ImageCache.storage.setObject(image, forKey: key, expiry: expiry)
        } catch let error {
            print(error)
        }
    }
    
    static func cacheSize() -> String {
        do {
            var url = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            url.appendPathComponent(cacheName)
            print(url)
            
            var folderSize = 0

            try (FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil)?.allObjects as? [URL])?.lazy.forEach {
                folderSize += try $0.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize ?? 0
            }
            
            let  byteCountFormatter =  ByteCountFormatter()
            byteCountFormatter.allowedUnits = .useMB
            byteCountFormatter.countStyle = .file
            let sizeToDisplay = byteCountFormatter.string(for: folderSize) ?? ""
            return sizeToDisplay
        } catch let error {
            print(error)
            return ""
        }
    }
    
    static func removeExpired() {
        do {
            try ImageCache.storage.removeExpiredObjects()
        } catch let error {
            print(error)
        }
    }
    
}
