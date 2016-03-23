//
//  main.swift
//  pam_nearbt-setup
//
//  Created by guoc on 23/03/2016.
//  Copyright © 2016 guoc. All rights reserved.
//

import Foundation
import CoreBluetooth

class CentralDelegate: NSObject, CBCentralManagerDelegate {
    
    let serviceUUID = CBUUID(string: kServiceUUID)
    let characteristicUUID = CBUUID(string: kCharacteristicUUID)
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == .PoweredOn {
            central.scanForPeripheralsWithServices([serviceUUID], options: nil)
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        let peripheralConfigurationFilePath = NSString(string:kPeripheralConfigurationFilePath).stringByExpandingTildeInPath
        if NSFileManager.defaultManager().fileExistsAtPath(peripheralConfigurationFilePath) {
            print("\(peripheralConfigurationFilePath) exists, overwrite? (y/n)")
            if let response = readLine(stripNewline: true) where response != "y" && response != "Y" {
                print("Canceled.")
                CFRunLoopStop(CFRunLoopGetMain())
                return
            }
        }
        NSFileManager.defaultManager().createFileAtPath(peripheralConfigurationFilePath, contents: peripheral.identifier.UUIDString.dataUsingEncoding(NSUTF8StringEncoding), attributes: [NSFilePosixPermissions:NSNumber(short:0400)])
        print("Setup finished.")
        CFRunLoopStop(CFRunLoopGetMain())
    }
}

print("Launch NearBT on your device, set secret if necessary and turn on \"Enabled\"")
let delegate = CentralDelegate()
let centralManager = CBCentralManager(delegate: delegate, queue: nil)

CFRunLoopRun()

