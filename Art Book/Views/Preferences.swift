//
//  Preferences.swift
//  Art Book
//
//  Created by xjbeta on 2018/10/1.
//  Copyright © 2018 xjbeta. All rights reserved.
//

import Cocoa

class Preferences: NSObject {
    static let shared = Preferences()
    
    private override init() {
    }
    
    private let prefs = UserDefaults.standard
    private let keys = PreferenceKeys.self
    
//    var favourites: [URL] {
//        get {
////            let bookmarks = defaults(.favourites) as? [String: Data] ?? [:]
////            favouriteKeys
//            
//            
//        }
//        set {
//            defaultsSet(newValue, forKey: .favourites)
//        }
//    }
    
//    func addFavourite(_ url: URL) {
//        var urlData = favourites[url.path]
//        if urlData == nil {
//            do {
//                let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
//                favourites[url.path] = data
//                urlData = data
//            } catch {
//                print("creatBookmarkError:\(error)")
//            }
//        }
//    }
    
    func setScales(_ value: Double, for view: ViewMode) {
        var dic = defaults(.scales) as? [String: Double] ?? [String: Double]()
        dic[view.rawValue] = value
        defaultsSet(dic, forKey: .scales)
    }
    
    func scales(for view: ViewMode) -> Double {
        guard let dic = defaults(.scales) as? [String: Double],
            let value = dic[view.rawValue] else {
            return 0.5
        }
        return value
    }
}

private extension Preferences {
    
    func defaults(_ key: PreferenceKeys) -> Any? {
        return prefs.value(forKey: key.rawValue) as Any?
    }
    
    func defaultsSet(_ value: Any, forKey key: PreferenceKeys) {
        prefs.setValue(value, forKey: key.rawValue)
    }
}

enum PreferenceKeys: String {
    case favourites
    case favouriteKeys
    case scales
}
