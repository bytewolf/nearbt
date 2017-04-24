//
//  PasswordGenerator.swift
//  NearBT
//
//  Created by guoc on 18/03/2016.
//  Copyright © 2016 guoc. All rights reserved.
//

import UIKit
import OneTimePassword

class OTPManager {
    
    let keychainAccountName = "name.guoc.NearBT.secret"
    
    static let sharedManager = OTPManager()
    
    fileprivate let userDefaultsKeyHasSetSecret = "hasSetSecret"
    var hasSetSecret: Bool {
        get {
            return Foundation.UserDefaults.standard.bool(forKey: userDefaultsKeyHasSetSecret)
        }
        set {
            Foundation.UserDefaults.standard.set(newValue, forKey: userDefaultsKeyHasSetSecret)
        }
    }
    
    fileprivate init() {}
    
    fileprivate func clear() {
        let query = [kSecClass as String : kSecClassGenericPassword]
        SecItemDelete(query as CFDictionary)
    }
    
    var secret: Data? {
        get {
            guard hasSetSecret else {
                return nil
            }
            let query = [
                kSecClass as String : kSecClassGenericPassword,
                kSecAttrAccount as String : keychainAccountName,
                kSecReturnData as String : kCFBooleanTrue,
                kSecMatchLimit as String : kSecMatchLimitOne ] as [String : Any]
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            guard status == errSecSuccess else {
                return nil
            }
            guard let secret = result as? Data else {
                fatalError("Fail to read secret from keychain: \(status)")
            }
            return secret
        }
        
        set(secret) {
            clear()
            guard let secret = secret else {
                return
            }
            let secAttrAccessible = UserDefaults.sharedUserDefaults.availableWhenDeviceLocked
                                  ? kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
                                  : kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            let query = [
                kSecClass as String : kSecClassGenericPassword,
                kSecAttrAccessible as String : secAttrAccessible,
                kSecAttrAccount as String : keychainAccountName,
                kSecValueData as String : secret ] as [String : Any]
            SecItemDelete(query as CFDictionary)
            let status = SecItemAdd(query as CFDictionary, nil)
            if (status == errSecSuccess) {
                hasSetSecret = true
            } else {
                fatalError("Fail to save secret in keychain: \(status)")
            }
        }
    }
    
    var currentPassword: String? {
        guard let secret = secret else {
            return nil
        }
        
        let deviceName = UIDevice.current.name
        let token = OTPToken(type: .timer, secret: secret, name: "NearBT Token", issuer: deviceName)
        
        token?.updatePassword()
        let password = token?.password
        return password
    }
    
    func resaveSecret() {
        let secret = self.secret
        self.secret = secret
    }
}
