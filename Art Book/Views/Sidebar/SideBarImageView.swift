//
//  SideBarImageView.swift
//  Art Book
//
//  Created by xjbeta on 2018/12/23.
//  Copyright © 2018 xjbeta. All rights reserved.
//

import Cocoa

class SideBarImageView: NSImageView {
    override func draw(_ dirtyRect: NSRect) {
        let context = NSGraphicsContext.current!
        let prev = context.imageInterpolation
        context.imageInterpolation = .none
        super.draw(dirtyRect)
        context.imageInterpolation = prev
    }
}
