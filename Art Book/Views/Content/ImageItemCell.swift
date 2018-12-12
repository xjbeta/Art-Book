//
//  ImageItemCel.swift
//  Example
//
//  Created by Wes Byrne on 1/28/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

//import Foundation
import Cocoa
import CollectionView

class ImageItemCell: CollectionViewPreviewCell {
    
    @IBOutlet weak var box: NSBox!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var textField: NSTextField!
    
    var node: FileNode?
    private var token: NSKeyValueObservation?

    override func awakeFromNib() {
        super.awakeFromNib()
    }
//    override var wantsUpdateLayer: Bool { return true }
    override func prepareForReuse() {
        super.prepareForReuse()
        box.isHidden = true
        loadImageOperation?.cancel()
        token?.invalidate()
        node = nil
        previewImage = nil
        markWidth = 0
        token = nil
    }
    

    override class var defaultReuseIdentifier: String {
        return "ImageItemCell"
    }
    
    override class func register(in collectionView: CollectionView) {
        collectionView.register(nib: NSNib(nibNamed: "ImageItemCell", bundle: nil)!,
                                forCellWithReuseIdentifier: self.defaultReuseIdentifier)
    }
    
    
//     MARK: - Selection & Highlighting
//    -------------------------------------------------------------------------------
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        setHighlight(selected)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        guard !self.selected else { return }
        setHighlight(highlighted)
    }
    
    func setHighlight(_ highlighted: Bool) {
        if highlighted {
            self.textField.layer?.backgroundColor = NSColor.systemBlue.cgColor
            self.textField.layer?.cornerRadius = 3
            self.box.isHidden = false
        } else {
            self.textField.layer?.backgroundColor = nil
            self.box.isHidden = true
        }
        self.needsDisplay = true
    }
    

    var isDisplaying = false {
        willSet {
            if newValue {
                requestPreviewImage()
                token = imageView?.observe(\.frame) { [weak self] imageView, _ in
                    guard imageView.frame.width != 0, 
                        imageView.frame.height != 0,
                        let inLiveResize = self?.inLiveResize,
                        !inLiveResize else { return }
                    self?.requestPreviewImage()
                }
            } else {
                token?.invalidate()
                loadImageOperation?.cancel()
            }
        }
    }
    
    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        guard imageView.frame.width != 0,
            imageView.frame.height != 0 else { return }
        requestPreviewImage()
    }
    
    var markWidth: CGFloat = 0
    
    func initNode(_ node: FileNode) {
        self.node = node
        textField?.stringValue = node.url?.lastPathComponent ?? ""
    }
    
    // NULL until metadata is loaded
    var previewImage: NSImage? {
        didSet {
            imageView.image = previewImage
        }
    }
    
    var loadImageOperation: BlockOperation?
    
    //MARK: Loading
    
    func requestPreviewImage(_ update: Bool = false) {
        if update {
            node?.savedImageSource = nil
        } else {
            guard markWidth != imageView.frame.width - 8 else { return }
            markWidth = imageView.frame.width - 8
        }

        loadImageOperation?.cancel()
        
        guard let scale = NSScreen.main?.backingScaleFactor,
            let url = self.node?.url else {
            return
        }
        
        let maxPixelSize = (Int(markWidth * scale / 100) + 1) * 100
        var cacheKey = "\(url.absoluteString) - \(maxPixelSize) - "
        
        if let date = url.fileModificationDate() {
            cacheKey += "\(date)"
        }
        
        if let image = ImageCache.shared.image(forKey: cacheKey) {
            previewImage = image
            return
        }
        
        loadImageOperation = BlockOperation()
        
        loadImageOperation?.addExecutionBlock { [weak self] in
            
            autoreleasepool {
                guard let imageSource = self?.node?.imageSource else { return }
                
                let options: [AnyHashable: Any] = [
                    // Ask ImageIO to create a thumbnail from the file's image data, if it can't find
                    // a suitable existing thumbnail image in the file.  We could comment out the following
                    // line if only existing thumbnails were desired for some reason (maybe to favor
                    // performance over being guaranteed a complete set of thumbnails).
                    kCGImageSourceCreateThumbnailFromImageAlways as AnyHashable: true,
                    kCGImageSourceThumbnailMaxPixelSize as AnyHashable: maxPixelSize
                ]
                
                
                guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {return}
                
                
                
                let image = NSImage(cgImage: thumbnail, size: NSZeroSize)
                ImageCache.shared.setImage(image, forKey: cacheKey)
                OperationQueue.main.addOperation { [weak self] in
                    guard url == self?.node?.url,
                        let newWidth = self?.imageView.frame.width,
                        self?.markWidth == newWidth - 8 else { return }
                    self?.previewImage = image
                }
                
                
            }
            
        }
        ImageCache.shared.imageLoadingQueue.addOperation(loadImageOperation!)
    }
}

