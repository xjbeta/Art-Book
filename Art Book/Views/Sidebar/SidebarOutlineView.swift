//
//  SidebarOutlineView.swift
//  Art Book
//
//  Created by xjbeta on 2018/10/1.
//  Copyright © 2018 xjbeta. All rights reserved.
//

import Cocoa

class SidebarOutlineView: NSOutlineView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
    
    override var acceptsFirstResponder: Bool {
        return false
    }
    
}
