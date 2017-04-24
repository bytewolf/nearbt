//
//  UserDefaults.swift
//  NearBT
//
//  Created by guoc on 18/03/2016.
//  Copyright © 2016 guoc. All rights reserved.
//

class UserDefaults {
    
    static let sharedUserDefaults = UserDefaults()
    
    fileprivate init() {}
    
    let userDefaultsKeyEnabled = "enabled"
    var enabled: Bool {
        get {
            return Foundation.UserDefaults.standard.bool(forKey: userDefaultsKeyEnabled)
        }
        set {
            Foundation.UserDefaults.standard.set(newValue, forKey: userDefaultsKeyEnabled)
        }
    }
    
    let userDefaultsKeyAvailableWhenDeviceLocked = "availableWhenDeviceLocked"
    var availableWhenDeviceLocked: Bool {
        get {
            return Foundation.UserDefaults.standard.bool(forKey: userDefaultsKeyAvailableWhenDeviceLocked)
        }
        set {
            Foundation.UserDefaults.standard.set(newValue, forKey: userDefaultsKeyAvailableWhenDeviceLocked)
        }
    }
}
