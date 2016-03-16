//
//  AppDelegate.swift
//  NearBT
//
//  Created by guoc on 12/03/2016.
//  Copyright © 2016 guoc. All rights reserved.
//

import UIKit
import CoreBluetooth
import OneTimePassword

let serviceUUID = CBUUID(string: kServiceUUID)
let characteristicUUID = CBUUID(string: kCharacteristicUUID)
let userDefaultsKeyTokenRef = "keychainRefOfToken"
let userDefaultsKeyEnabled = "enabled"
var enabled: Bool {
    get {
        return NSUserDefaults.standardUserDefaults().boolForKey(userDefaultsKeyEnabled)
    }
    set {
        NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: userDefaultsKeyEnabled)
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CBPeripheralManagerDelegate {
    
    var window: UIWindow?

    var peripheralManager: CBPeripheralManager!
    var characteristic: CBMutableCharacteristic!
    
    func getNewCharacteristicValue() -> NSData? {
        if NSUserDefaults.standardUserDefaults().boolForKey(userDefaultsKeyEnabled) == false {
            return nil
        }
        guard let keychainItemRef = NSUserDefaults.standardUserDefaults().objectForKey(userDefaultsKeyTokenRef) as? NSData else {
            return nil
        }
        let otpToken = OTPToken(keychainItemRef: keychainItemRef)
        guard otpToken != nil else {
            return nil
        }
        otpToken.updatePassword()
        let result = otpToken.password.dataUsingEncoding(NSUTF8StringEncoding)!
        otpToken.saveToKeychain()
        NSUserDefaults.standardUserDefaults().setObject(otpToken.keychainItemRef, forKey: userDefaultsKeyTokenRef)
        return result
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        return true
    }

    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        guard (peripheralManager.state == .PoweredOn) else {
            return;
        }
        characteristic = CBMutableCharacteristic(type: characteristicUUID, properties: [.Read, .Notify, .NotifyEncryptionRequired], value: nil, permissions: [.Readable, .ReadEncryptionRequired])
        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [characteristic]
        peripheralManager.addService(service) // the service is cached and you can no longer make changes to it
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        print("add service")
        if (error != nil) {
            print(error)
        }
        print(serviceUUID)
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceUUID]])
    }
    
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        print("start advertising")
        if ((error) != nil) {
            print(error!.localizedDescription);
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveReadRequest request: CBATTRequest) {
        guard request.characteristic.UUID == characteristicUUID else {
            peripheral.respondToRequest(request, withResult: .AttributeNotFound)
            return
        }
        guard let updatedValue = getNewCharacteristicValue() else {
            peripheral.respondToRequest(request, withResult: .AttributeNotFound)
            return
        }
        guard request.offset <= updatedValue.length else {
            peripheral.respondToRequest(request, withResult: .InvalidOffset)
            return
        }
        request.value = updatedValue.subdataWithRange(NSMakeRange(request.offset, updatedValue.length - request.offset))
        request.value = updatedValue
        peripheralManager.respondToRequest(request, withResult: .Success)
        return
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        guard characteristic.UUID == characteristicUUID else {
            return
        }
        guard let updatedValue = getNewCharacteristicValue() else {
            return
        }
        let didSendValue = peripheralManager.updateValue(updatedValue, forCharacteristic: self.characteristic, onSubscribedCentrals: nil)
        if !didSendValue {
            print("waiting for resend …")
        }
    }
    
    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
        // resend
        guard let updatedValue = getNewCharacteristicValue() else {
            return
        }
        let didSendValue = peripheralManager.updateValue(updatedValue, forCharacteristic: self.characteristic, onSubscribedCentrals: nil)
        if !didSendValue {
            assertionFailure("Fail to send value update.")
        }
    }

    func applicationDidBecomeActive(application: UIApplication) {
        if let viewController = window?.rootViewController as? ViewController {
            viewController.resetView()
        }
    }

    
}
