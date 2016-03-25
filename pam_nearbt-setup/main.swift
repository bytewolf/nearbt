//
//  main.swift
//  pam_nearbt-setup
//
//  Created by guoc on 23/03/2016.
//  Copyright © 2016 guoc. All rights reserved.
//

import Foundation
import CoreBluetooth

class CentralDelegate: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var targetPeripheral: CBPeripheral?
    
    let serviceUUID = CBUUID(string: kServiceUUID)
    let characteristicUUID = CBUUID(string: kCharacteristicUUID)
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == .PoweredOn {
            central.scanForPeripheralsWithServices([serviceUUID], options: nil)
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        peripheral.delegate = self
        targetPeripheral = peripheral
        central.connectPeripheral(peripheral, options: nil)
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Fail to connect peripheral: \(error?.localizedDescription)")
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        guard let service = peripheral.services?.last where service.UUID == serviceUUID else {
            print("Target service is not found.")
            return
        }
        peripheral.discoverCharacteristics([characteristicUUID], forService:service)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        guard let characteristic = service.characteristics?.last where characteristic.UUID == characteristicUUID else {
            print("Target characteristic is not found.")
            return
        }
        peripheral.readValueForCharacteristic(characteristic)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if let error = error {
            print("Setup failure: \(error.localizedDescription)")
            CFRunLoopStop(CFRunLoopGetMain())
        }
        
        func setupPeripheral() {
            print("(1/3) Setup Peripheral")
            let peripheralConfigurationFilePath = NSString(string:kGlobalPeripheralConfigurationFilePath).stringByExpandingTildeInPath
            if NSFileManager.defaultManager().fileExistsAtPath(peripheralConfigurationFilePath) {
                print("\(peripheralConfigurationFilePath) exists, overwrite? (y/n) ", terminator:"")
                if let response = readLine(stripNewline: true) where response != "y" && response != "Y" {
                    print("Canceled.")
                    return
                }
            }
            NSFileManager.defaultManager().createFileAtPath(peripheralConfigurationFilePath, contents: peripheral.identifier.UUIDString.dataUsingEncoding(NSUTF8StringEncoding), attributes: [NSFilePosixPermissions:NSNumber(short:0400)])
            print("Success.")
            return
        }
        
        func setupSecret() {
            print("(2/3) Setup Secret")
            let defaultUserSecretFilePath = NSString(string: kDefaultGlobalSecretFilePath).stringByExpandingTildeInPath
            if NSFileManager.defaultManager().fileExistsAtPath(defaultUserSecretFilePath) {
                print("\(defaultUserSecretFilePath) exists, overwrite? (y/n) ", terminator:"")
                if let response = readLine(stripNewline: true) where response != "y" && response != "Y" {
                    print("Canceled.")
                    return
                }
            }
            var secret = ""
            repeat {
                secret = String.fromCString(getpass("Please enter your secret: ")) ?? ""
            } while secret.isEmpty
            NSFileManager.defaultManager().createFileAtPath(defaultUserSecretFilePath, contents: secret.dataUsingEncoding(NSUTF8StringEncoding), attributes: [NSFilePosixPermissions:NSNumber(short:0400)])
            print("Success.")
        }
        
        func setupPAM() {
            print("(3/3) Setup PAM")
            print("Add pam_nearbt in some files under /etc/pam.d/")
            print("e.g.")
            print("Add the following line at the beginning of /etc/pam.d/screensaver, so that you can unlock screensaver without password by using NearBT.")
            print("auth       sufficient     pam_nearbt.so min_rssi=-55 timeout=10")
            print("Note: this example is only for testing. It may increase security risks.")
        }
        
        setupPeripheral()
        setupSecret()
        setupPAM()
        
        print("Setup finished.")
        CFRunLoopStop(CFRunLoopGetMain())
    }
    
}

print("Launch NearBT on your device, set secret if necessary and turn on \"Enabled\"")
print("Bluetooth pairing may be requested.")

let delegate = CentralDelegate()
let centralManager = CBCentralManager(delegate: delegate, queue: nil)

CFRunLoopRun()
