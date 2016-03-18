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
    
    let userDefaultsKeyEnabled = "enabled"
    var enabled: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(userDefaultsKeyEnabled)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: userDefaultsKeyEnabled)
        }
    }
    
    let userDefaultsKeyHasSetSecret = "hasSetSecret"
    var hasSetSecret: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(userDefaultsKeyHasSetSecret)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: userDefaultsKeyHasSetSecret)
        }
    }
    
    let userDefaultsKeyAvailableWhenDeviceLocked = "availableWhenDeviceLocked"
    var availableWhenDeviceLocked: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(userDefaultsKeyAvailableWhenDeviceLocked)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: userDefaultsKeyAvailableWhenDeviceLocked)
        }
    }
}
