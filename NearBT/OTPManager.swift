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
    
    static let sharedManager = OTPManager()
    
    static var cachedToken: OTPToken? = nil
    
    private init() {}
    
    func setSecret(secret: String) {
        let deviceName = UIDevice.currentDevice().name
        let otpToken = OTPToken(type: .Timer, secret: secret.dataUsingEncoding(NSUTF8StringEncoding), name: "NearBT Token", issuer: deviceName)
        guard otpToken.saveToKeychain() else {
            fatalError("Fail to save token to keychain")
        }
        NSUserDefaults.standardUserDefaults().setObject(otpToken.keychainItemRef, forKey: userDefaultsKeyTokenRef)
    }
    
    var currentPassword: String! {
        guard let keychainItemRef = NSUserDefaults.standardUserDefaults().objectForKey(userDefaultsKeyTokenRef) as? NSData else {
            assertionFailure("There is no keychain item ref in user defaults.")
            return nil
        }
        let tokenInKeychain = OTPToken(keychainItemRef: keychainItemRef)
        let tokenCacheRequired = NSUserDefaults.standardUserDefaults().boolForKey(userDefaultsKeyTokenCacheRequired)
        if tokenCacheRequired && tokenInKeychain != nil {
            OTPManager.cachedToken = tokenInKeychain
        }
        guard let token = tokenCacheRequired ? OTPManager.cachedToken : tokenInKeychain else {
            if OTPManager.cachedToken == nil { assertionFailure("`OTPManager` has no cached token") }
            if tokenInKeychain == nil { assertionFailure("There is no token in keychain") }
            return nil
        }
        token.updatePassword()
        let result = token.password
        token.saveToKeychain()
        NSUserDefaults.standardUserDefaults().setObject(token.keychainItemRef, forKey: userDefaultsKeyTokenRef)
        return result
    }
}
