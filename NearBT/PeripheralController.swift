//
//  PeripheralController.swift
//  NearBT
//
//  Created by guoc on 17/03/2016.
//  Copyright © 2016 guoc. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol PeripheralControllerDelegate {
    func getNewCharacteristicValue() -> NSData?
}

let notificationKeyBluetoothStateChanged = "kBluetoothStateChanged"

class PeripheralController : NSObject, CBPeripheralManagerDelegate {
    
    enum State {
        case Stopped
        case Starting
        case Started
    }
    
    enum BluetoothState {
        case Unknown
        case Unsupported
        case PowerOff
        case PairingRequired
        case Ready
    }
    
    var state: State = .Stopped
    var bluetoothState: BluetoothState = .Unknown {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName(notificationKeyBluetoothStateChanged, object: self)
        }
    }
    var peripheralManager: CBPeripheralManager!
    var characteristic: CBMutableCharacteristic!
    
    let serviceUUID = CBUUID(string: kServiceUUID)
    let characteristicUUID = CBUUID(string: kCharacteristicUUID)
    private let timeout = 5.0
    
    static let sharedController = PeripheralController()
    
    private override init() { super.init() }
    
    func start() {
        if state == .Started {
            return
        }
        state = .Starting
        peripheralManager = CBPeripheralManager(delegate: nil, queue: dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0))
        peripheralManager.delegate = self
    }
    
    func stop() {
        peripheralManager.stopAdvertising()
        peripheralManager.delegate = nil
        peripheralManager = nil
        state = .Stopped
    }
    
    func getNewCharacteristicValue() -> NSData? {
        guard let password = OTPManager.sharedManager.currentPassword else {
            let notification = UILocalNotification()
            notification.alertBody = "NearBT couldn't generate password.\n"
                + (OTPManager.sharedManager.hasSetSecret
                    ? "Unlock device \nor enable the option: Available When Device Locked."
                    : "Set secret in NearBT.")
            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
            return nil
        }
        let result = password.dataUsingEncoding(NSUTF8StringEncoding)!
        return result
    }
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .Unknown, .Resetting:
            break
        case .Unsupported:
            bluetoothState = .Unsupported
        case .Unauthorized:
            bluetoothState = .PairingRequired
        case .PoweredOff:
            bluetoothState = .PowerOff
        case .PoweredOn:
            bluetoothState = .Ready
        }
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
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceUUID]])
    }
    
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        state = .Started
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
    
}
