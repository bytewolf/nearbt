//
//  AppDelegate.swift
//  NearBT
//
//  Created by guoc on 12/03/2016.
//  Copyright © 2016 guoc. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let userNotificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(userNotificationSettings)
        if UserDefaults.sharedUserDefaults.enabled {
            PeripheralController.sharedController.start()
        }
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
