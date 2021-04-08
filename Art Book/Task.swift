//
//  Task.swift
//  Art Book
//
//  Created by xjbeta on 3/15/21.
//  Copyright © 2021 xjbeta. All rights reserved.
//

import Cocoa

class Task: NSObject {

    static let shared = Task()
    
    private override init() {
    }
    
    lazy var imageExtensions: [String] = {
        return NSImage.imageTypes.compactMap {
            UTTypeCopyAllTagsWithClass($0 as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue()
        }.compactMap {
            $0 as NSArray as? [String]
        }.flatMap {
            $0
        }
    }()
    
    
    func findAllFiles(_ dir: String) -> [String] {
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launchPath = "/usr/bin/find"
        
        var args = [dir]
        
        imageExtensions.enumerated().forEach {
            if $0.offset != 0 {
                args.append("-o")
            }
            args.append("-name")
            args.append("*.\($0.element)")
        }
        
        task.arguments = args
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        var re = [String]()
        
        if let output = String(data: data, encoding: .utf8) {
            re = output.components(separatedBy: "\n").filter({ $0 != "" })
        }
        
        pipe.fileHandleForReading.closeFile()
        task.terminate()
        
        return re
    }
    
    func lsFiles(_ dir: String) -> [(isDir: Bool, path: String)] {
        var dir = dir
        if dir.last != "/" {
            dir.append("/")
        }
        
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launchPath = "/bin/ls"
        
        task.arguments = ["-p", dir]
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        var re = [(isDir: Bool, path: String)]()
        
        if let output = String(data: data, encoding: .utf8) {
            let list = output.components(separatedBy: "\n").filter({ $0 != "" })
            
            re = list.map { str -> (isDir: Bool, path: String) in
                var s = str
                let isDir = s.last == "/"
                if isDir {
                    s.removeLast()
                }
                s = s.replacingOccurrences(of: ":", with: "/")
                s = dir + s
                return (isDir, s)
            }
        }
        
        return re
    }
    
    
}
