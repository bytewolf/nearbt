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
    func getNewCharacteristicValue() -> Data?
}

let notificationKeyBluetoothStateChanged = "kBluetoothStateChanged"

class PeripheralController : NSObject, CBPeripheralManagerDelegate {
    
    enum State {
        case stopped
        case starting
        case started
    }
    
    enum BluetoothState {
        case unknown
        case unsupported
        case powerOff
        case pairingRequired
        case ready
    }
    
    var state: State = .stopped
    var bluetoothState: BluetoothState = .unknown {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: notificationKeyBluetoothStateChanged), object: self)
            }
        }
    }
    var peripheralManager: CBPeripheralManager!
    var characteristic: CBMutableCharacteristic!
    
    let serviceUUID = CBUUID(string: kServiceUUID)
    let characteristicUUID = CBUUID(string: kCharacteristicUUID)
    fileprivate let timeout = 5.0
    
    static let sharedController = PeripheralController()
    
    fileprivate override init() { super.init() }
    
    func start() {
        if state == .started {
            return
        }
        state = .starting
        peripheralManager = CBPeripheralManager(delegate: nil, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive))
        peripheralManager.delegate = self
    }
    
    func stop() {
        peripheralManager.stopAdvertising()
        peripheralManager.delegate = nil
        peripheralManager = nil
        state = .stopped
    }
    
    func getNewCharacteristicValue() -> Data? {
        guard let password = OTPManager.sharedManager.currentPassword else {
            let notification = UILocalNotification()
            notification.alertBody = "NearBT couldn't generate password.\n"
                + (OTPManager.sharedManager.hasSetSecret
                    ? "Unlock device \nor enable the option: available when device locked."
                    : "Set secret in NearBT.")
            UIApplication.shared.presentLocalNotificationNow(notification)
            return nil
        }
        let result = password.data(using: String.Encoding.utf8)!
        return result
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unknown, .resetting:
            break
        case .unsupported:
            bluetoothState = .unsupported
        case .unauthorized:
            bluetoothState = .pairingRequired
        case .poweredOff:
            bluetoothState = .powerOff
        case .poweredOn:
            bluetoothState = .ready
        }
        guard (peripheralManager.state == .poweredOn) else {
            return;
        }
        characteristic = CBMutableCharacteristic(type: characteristicUUID, properties: [.read, .notify, .notifyEncryptionRequired], value: nil, permissions: [.readable, .readEncryptionRequired])
        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [characteristic]
        peripheralManager.add(service) // the service is cached and you can no longer make changes to it
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print("add service")
        if (error != nil) {
            print(error)
        }
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceUUID]])
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        state = .started
        print("start advertising")
        if ((error) != nil) {
            print(error!.localizedDescription);
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        guard request.characteristic.uuid == characteristicUUID else {
            peripheral.respond(to: request, withResult: .attributeNotFound)
            return
        }
        guard let updatedValue = getNewCharacteristicValue() else {
            peripheral.respond(to: request, withResult: .attributeNotFound)
            return
        }
        guard request.offset <= updatedValue.count else {
            peripheral.respond(to: request, withResult: .invalidOffset)
            return
        }
        request.value = updatedValue.subdata(in: NSMakeRange(request.offset, updatedValue.count - request.offset))
        request.value = updatedValue
        peripheralManager.respond(to: request, withResult: .success)
        return
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        guard characteristic.uuid == characteristicUUID else {
            return
        }
        guard let updatedValue = getNewCharacteristicValue() else {
            return
        }
        let didSendValue = peripheralManager.updateValue(updatedValue, for: self.characteristic, onSubscribedCentrals: nil)
        if !didSendValue {
            print("waiting for resend …")
        }
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // resend
        guard let updatedValue = getNewCharacteristicValue() else {
            return
        }
        let didSendValue = peripheralManager.updateValue(updatedValue, for: self.characteristic, onSubscribedCentrals: nil)
        if !didSendValue {
            assertionFailure("Fail to send value update.")
        }
    }
    
}
