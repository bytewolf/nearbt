//
//  AppDelegate.swift
//  NearBT
//
//  Created by guoc on 12/03/2016.
//  Copyright © 2016 guoc. All rights reserved.
//

import UIKit
import OneTimePassword

let userDefaultsKeyTokenRef = "keychainRefOfToken"
let userDefaultsKeyEnabled = "enabled"
let userDefaultsKeyTokenCacheRequired = "tokenCacheRequired"
var enabled: Bool {
    get {
        return NSUserDefaults.standardUserDefaults().boolForKey(userDefaultsKeyEnabled)
    }
    set {
        NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: userDefaultsKeyEnabled)
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PeripheralControllerDelegate {
    
    var window: UIWindow?

    var peripheralController: PeripheralController!
    var cachedToken: OTPToken? = nil
    
    func getNewCharacteristicValue() -> NSData? {
        if NSUserDefaults.standardUserDefaults().boolForKey(userDefaultsKeyEnabled) == false {
            return nil
        }
        guard let keychainItemRef = NSUserDefaults.standardUserDefaults().objectForKey(userDefaultsKeyTokenRef) as? NSData else {
            return nil
        }
        let tokenInKeychain = OTPToken(keychainItemRef: keychainItemRef)
        let tokenCacheRequired = NSUserDefaults.standardUserDefaults().boolForKey(userDefaultsKeyTokenCacheRequired)
        if tokenCacheRequired && tokenInKeychain != nil {
            cachedToken = tokenInKeychain
        }
        guard let token = tokenCacheRequired ? cachedToken : tokenInKeychain else {
            return nil
        }
        token.updatePassword()
        let result = token.password.dataUsingEncoding(NSUTF8StringEncoding)!
        token.saveToKeychain()
        NSUserDefaults.standardUserDefaults().setObject(token.keychainItemRef, forKey: userDefaultsKeyTokenRef)
        return result
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let userNotificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(userNotificationSettings)
        peripheralController = PeripheralController(delegate: self)
        peripheralController.start()
        return true
    }

    func applicationDidBecomeActive(application: UIApplication) {
        if let viewController = window?.rootViewController as? ViewController {
            viewController.resetViewAnimated(true)
        }
    }

    func applicationWillTerminate(application: UIApplication) {
        let notification: UILocalNotification = {
            let notification = UILocalNotification()
            notification.alertTitle = "NearBT will terminate"
            notification.alertBody = "Relaunch to keep it working in background."
            return notification
        }()
        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }
    
}
