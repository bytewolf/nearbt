//
//  UserDefaults.swift
//  NearBT
//
//  Created by guoc on 18/03/2016.
//  Copyright © 2016 guoc. All rights reserved.
//

class UserDefaults {
    
    static let sharedUserDefaults = UserDefaults()
    
    private init() {}
    
    let userDefaultsKeyTokenRef = "keychainRefOfToken"
    var tokenRef: NSData? {
        get {
            return NSUserDefaults.standardUserDefaults().objectForKey(userDefaultsKeyTokenRef) as? NSData
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: userDefaultsKeyTokenRef)
        }
    }
    
    let userDefaultsKeyEnabled = "enabled"
    var enabled: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(userDefaultsKeyEnabled)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: userDefaultsKeyEnabled)
        }
    }
    
    let userDefaultsKeyTokenCacheRequired = "tokenCacheRequired"
    var tokenCacheRequired: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(userDefaultsKeyTokenCacheRequired)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: userDefaultsKeyTokenCacheRequired)
        }
    }
}
