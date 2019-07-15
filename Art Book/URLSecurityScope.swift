//
//  URLSecurityScope.swift
//  Aria2D
//
//  Created by xjbeta on 2017/1/24.
//  Copyright © 2017年 xjbeta. All rights reserved.
//

import Foundation

// MARK: - Security-Scoped


class URLSecurityScope: NSObject {
    static func resolvingBookmark(_ data: Data) -> URL? {
        do {
            var bool = false
            let url = try URL(resolvingBookmarkData: data,
                              options: .withSecurityScope,
                              relativeTo: nil,
                              bookmarkDataIsStale: &bool)
//            let _ = url.startAccessingSecurityScopedResource()
            return url
        } catch {
            Log("resolveBookmarkError\(error)")
            return nil
        }
    }
    
    static func bookmarkData(for url: URL) -> Data? {
        do {
            let data = try url.bookmarkData(options: .withSecurityScope,
                                            includingResourceValuesForKeys: nil,
                                            relativeTo: nil)
            return data
        } catch {
            Log("creatBookmarkError:\(error)")
            return nil
        }
    }
    
}
