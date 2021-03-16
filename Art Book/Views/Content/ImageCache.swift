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
        
        let imageDiskStorage = try! DiskStorage<Image>(config: .init(name: imageCacheName), transformer: TransformerFactory.forImage())
        let imageMemoryStorage = MemoryStorage<Image>(config: .init(expiry: .seconds(3600), countLimit: 50, totalCostLimit: 0))
        imageStorage = HybridStorage<Image>(memoryStorage: imageMemoryStorage,
                                            diskStorage: imageDiskStorage)
        
        ratioStorage = try! DiskStorage<[String: CGFloat]>(config: .init(name: ratioCacheName), transformer: TransformerFactory.forCodable(ofType: [String: CGFloat].self))
        
        ratiosDic = (try? ratioStorage.object(forKey: ratioCacheName)) ?? [:]
        
        imageLoadingQueue = OperationQueue()
        imageLoadingQueue.name = "com.xjbeta.Art Book.imageLoadingQueue"
    }
    
    let imageCacheName: String
    let ratioCacheName: String
    
    let imageStorage: HybridStorage<Image>
    let ratioStorage: DiskStorage<[String: CGFloat]>
    var ratiosDic: [String: CGFloat]
    
    let imageLoadingQueue: OperationQueue
    
    var loadImageOperations = [String: Operation]()
    var loadingImageIds = [String]()
    
    func cleanDics() {
        imageLoadingQueue.cancelAllOperations()
        imageStorage.removeAllKeyObservers()
        loadingImageIds.removeAll()
        imageStorage.memoryStorage.removeAll()
    }
    
    func cleanFinishedOperations() {
        loadImageOperations.filter {
            $0.value.isCancelled || $0.value.isFinished
            }.forEach {
                loadImageOperations.removeValue(forKey: $0.key)
        }
    }
    
    
    func requestPreviewImage(_ node: FileNode, _ width: CGFloat, _ update: Bool = false) {
        let imageCache = ImageCache.shared
        guard let _ = node.url else { return }
        
        let markPixelSize = node.maxPixelSize(width)
        let cacheKey = node.cacheKey(markPixelSize)
        
        if update {
            node.savedImageSource = nil
            try? imageCache.imageStorage.removeObject(forKey: cacheKey)
        }
        
        guard !imageCache.loadingImageIds.contains(cacheKey) else {
            return
        }
        
        if let exists = try? imageCache.imageStorage.existsObject(forKey: cacheKey),
            exists {
            return
        }
        
        let blockOperation = BlockOperation()
        imageCache.loadImageOperations[cacheKey] = blockOperation
        
        imageCache.loadingImageIds.append(cacheKey)
        
        blockOperation.addExecutionBlock {
            autoreleasepool {
                guard let imageSource = node.imageSource else { return }
                let options: [AnyHashable: Any] = [
                    // Ask ImageIO to create a thumbnail from the file's image data, if it can't find
                    // a suitable existing thumbnail image in the file.  We could comment out the following
                    // line if only existing thumbnails were desired for some reason (maybe to favor
                    // performance over being guaranteed a complete set of thumbnails).
                    kCGImageSourceCreateThumbnailFromImageAlways as AnyHashable: true,
                    kCGImageSourceThumbnailMaxPixelSize as AnyHashable: markPixelSize
                ]
                guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {return}
                
                let image = NSImage(cgImage: thumbnail, size: NSZeroSize)
                let imageCache = ImageCache.shared
                
                imageCache.setImage(image, forKey: cacheKey)
                DispatchQueue.main.async {
                    imageCache.loadingImageIds.removeAll(where: { $0 == cacheKey })
                }
            }
        }
        imageCache.imageLoadingQueue.addOperation(blockOperation)
    }
    
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
    
    func saveRatios() {
        try? ratioStorage.setObject(ratiosDic, forKey: ratioCacheName)
    }
    
}
