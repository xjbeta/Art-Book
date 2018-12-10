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
    
    static let shared = ImageCache()
    
    private override init() {
        imageCacheName = "Image Cache"
        ratioCacheName = "Image Ratio Cache"
        
        let config = DiskConfig(name: imageCacheName)
        imageStorage = try! DiskStorage<Image>(config: config, transformer: TransformerFactory.forImage())
        
        let config1 = DiskConfig(name: ratioCacheName)
        ratioStorage = try! DiskStorage<[String: CGFloat]>(config: config1, transformer: TransformerFactory.forCodable(ofType: [String: CGFloat].self))
        
        ratiosDic = (try? ratioStorage.object(forKey: ratioCacheName)) ?? [:]
        
        imageLoadingQueue = OperationQueue()
        imageLoadingQueue.name = "CoverViewItem ImageView Loading Queue"
    }
    
    let imageCacheName: String
    let ratioCacheName: String
    
    let imageStorage: DiskStorage<Image>
    let ratioStorage: DiskStorage<[String: CGFloat]>
    var ratiosDic: [String: CGFloat]
    
    let imageLoadingQueue: OperationQueue
    
    func image(forKey key: String) -> Image? {
        return try? imageStorage.object(forKey: key)
    }
    
    func setImage(_ image: Image, forKey key: String) {
        var expiry = Expiry.seconds(2 * 3600)
        if let widthStr = key.components(separatedBy: " - ").last,
            let width = Int(widthStr),
            width < 500 {
            expiry = .seconds(3600 * 24 * 15)
        }
        
        do {
            try imageStorage.setObject(image, forKey: key, expiry: expiry)
        } catch let error {
            Log(error)
        }
    }
    
    func cacheSize() -> String {
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
    
    func removeExpired() {
        do {
            try imageStorage.removeExpiredObjects()
            try ratioStorage.removeExpiredObjects()
        } catch let error {
            Log(error)
        }
    }
    
    func ratio(forKey key: String) -> CGFloat? {
        return ratiosDic[key]
    }
    
    func setRatio(_ ratio: CGFloat, forKey key: String) {
        ratiosDic[key] = ratio
    }
    
}
