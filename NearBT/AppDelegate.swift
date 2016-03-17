//
//  AppDelegate.swift
//  NearBT
//
//  Created by guoc on 12/03/2016.
//  Copyright © 2016 guoc. All rights reserved.
//

import UIKit

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
    
    func getNewCharacteristicValue() -> NSData? {
        let result = OTPManager.sharedManager.currentPassword.dataUsingEncoding(NSUTF8StringEncoding)!
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
