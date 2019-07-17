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
    
    var favourites: [(String, URL)]? {
        get {
            guard let saved = defaults(.favourites) as? [[String]] else {
                return nil
            }
            return saved.compactMap { i -> (String, URL)? in
                guard let id = i[safe: 0],
                    let uStr = i[safe: 1],
                    let url = URL(string: uStr) else {
                    return nil
                }
                return (id, url)
            }
        }
    }

    
    func removeFavourite(_ id: String) {
        guard var favourites = defaults(.favourites) as? [[String]] else { return }
        favourites.removeAll {
            $0.contains(where: { $0 == id })
        }
        defaultsSet(favourites, forKey: .favourites)
    }
    
    
    func addFavourite(_ url: URL) {
        var f = defaults(.favourites) as? [[String]] ?? [[String]]()
        let newKey = "\(UUID())"
        f.append([newKey, url.absoluteString])
        defaultsSet(f, forKey: .favourites)
    }
    
    func setScales(_ value: Double, for view: MainWindowController.ViewMode) {
        var dic = defaults(.scales) as? [String: Double] ?? [String: Double]()
        dic[view.rawValue] = value
        defaultsSet(dic, forKey: .scales)
    }
    
    func scales(for view: MainWindowController.ViewMode) -> Double {
        guard let dic = defaults(.scales) as? [String: Double],
            let value = dic[view.rawValue] else {
            return 0.5
        }
        return value
    }
    
    func prepareUserDefaults() {
        if let _ = defaults(.favourites) as? [String: Data] {
            prefs.removeObject(forKey: PreferenceKeys.favourites.rawValue)
        }
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
