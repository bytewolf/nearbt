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
        /* 
           On iOS 9, this is not a good place to remind user that the application will terminate.
           This method is called only when: the app is in foreground, users double tap home button,
           and slide up to kill the app.
           The method is not called when the app is in background and killed by users.
        */
    }
    
    func applicationDidReceiveMemoryWarning(application: UIApplication) {
        let notification: UILocalNotification = {
            let notification = UILocalNotification()
            notification.alertTitle = "NearBT will terminate"
            notification.alertBody = "Relaunch to keep it working in background."
            return notification
        }()
        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }
    
}
