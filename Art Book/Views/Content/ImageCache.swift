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
    static let imageCacheName = "Image Cache"
    static let ratioCacheName = "Image Ratio Cache"
    
    static let imageStorage: DiskStorage<Image> = {
        let config = DiskConfig(name: imageCacheName)
        
        let storage = try! DiskStorage<Image>(config: config, transformer: TransformerFactory.forImage())
        return storage
    }()
    
    static func image(forKey key: String) -> Image? {
        return try? ImageCache.imageStorage.object(forKey: key)
    }
    
    static func setImage(_ image: Image, forKey key: String) {
        var expiry = Expiry.seconds(2 * 3600)
        if let widthStr = key.components(separatedBy: " - ").last,
            let width = Int(widthStr),
            width < 500 {
            expiry = .seconds(3600 * 24 * 15)
        }
        
        do {
            try ImageCache.imageStorage.setObject(image, forKey: key, expiry: expiry)
        } catch let error {
            Log(error)
        }
    }
    
    static func cacheSize() -> String {
        do {
            var url = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            url.appendPathComponent(imageCacheName)
            Log(url)
            
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
            Log(error)
            return ""
        }
    }
    
    static func removeExpired() {
        do {
            try ImageCache.imageStorage.removeExpiredObjects()
            try ImageCache.ratioStorage.removeExpiredObjects()
        } catch let error {
            Log(error)
        }
    }
    
    
    static let ratioStorage: DiskStorage<CGFloat> = {
        let config = DiskConfig(name: ratioCacheName)
        let storage = try! DiskStorage<CGFloat>(config: config, transformer: TransformerFactory.forCodable(ofType: CGFloat.self))
        return storage
    }()
    
    static func ratio(forKey key: String) -> CGFloat? {
        return try? ImageCache.ratioStorage.object(forKey: key)
    }
    
    static func setRatio(_ ratio: CGFloat, forKey key: String) {
        let expiry = Expiry.seconds(3600 * 24 * 90)
        do {
            try ImageCache.ratioStorage.setObject(ratio, forKey: key, expiry: expiry)
        } catch let error {
            Log(error)
        }
    }
    
}
