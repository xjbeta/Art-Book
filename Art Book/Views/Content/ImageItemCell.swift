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
//        loadImageOperation?.cancel()
        token?.invalidate()
        node = nil
        markPixelSize = 0
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
                token = imageView?.observe(\.frame) { [weak self] imageView, _ in
                    guard imageView.frame.width != 0, 
                        imageView.frame.height != 0,
                        let inLiveResize = self?.inLiveResize,
                        !inLiveResize else { return }
                    self?.initImageView(true)
                }
            } else {
                token?.invalidate()
            }
        }
    }
    
    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        guard let node = node,
            imageView.frame.width != 0,
            imageView.frame.height != 0 else { return }
        ImageCache.shared.requestPreviewImage(node, imageView.frame.width)
    }
    
    var markPixelSize: CGFloat = 0
    
    func initNode(_ node: FileNode) {
        self.node = node
        textField?.stringValue = node.url?.lastPathComponent ?? ""
        initImageView(true)
    }
    
    func initImageView(_ requestImage: Bool = false) {
        guard let node = node else { return }
        let markPixelSize = node.maxPixelSize(imageView.frame.width)
        let cacheKey = node.cacheKey(markPixelSize)
        
        imageView.bind(.value, to: ImageCache.shared, withKeyPath: "imagesDic.\(cacheKey)", options: [.continuouslyUpdatesValue: true])
        if requestImage {
            ImageCache.shared.requestPreviewImage(node, imageView.frame.width)
        }
    }
}

