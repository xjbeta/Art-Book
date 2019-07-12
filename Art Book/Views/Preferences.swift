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
    
    var favourites: [URL] {
        get {
            guard var favourites = defaults(.favourites) as? [String: Data] else { return [] }
            let keys = favourites.keys.sorted()
            var invalidKey = [String]()
            let urls = keys.compactMap { key -> URL? in
                guard let data = favourites[key],
                    let url = URLSecurityScope.resolvingBookmark(data) else {
                        invalidKey.append(key)
                        return nil
                }
                return url
            }
            
            invalidKey.forEach {
                favourites[$0] = nil
            }
            defaultsSet(favourites, forKey: .favourites)
            return urls
        }
    }

    
    func removeFavourite(_ url: URL) {
        guard var favourites = defaults(.favourites) as? [String: Data] else { return }
        
        favourites.filter {
            URLSecurityScope.resolvingBookmark($0.value) == url
            }.keys.forEach {
                favourites.removeValue(forKey: $0)
        }
        defaultsSet(favourites, forKey: .favourites)
    }
    
    
    func addFavourite(_ url: URL) {
        var favourites = defaults(.favourites) as? [String: Data] ?? [String: Data]()
        var newKey = "1.0"
        if let maxKeyStr = favourites.keys.max(), let maxKey = Double(maxKeyStr) {
            newKey = "\(maxKey + 1)"
        } else {
            assert(favourites.count == 0)
        }
        
        favourites[newKey] = URLSecurityScope.bookmarkData(for: url)
        
        defaultsSet(favourites, forKey: .favourites)
    }
    
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
    case scales
}
