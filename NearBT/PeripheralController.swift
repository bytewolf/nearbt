//
//  PeripheralController.swift
//  NearBT
//
//  Created by guoc on 17/03/2016.
//  Copyright © 2016 guoc. All rights reserved.
//

import CoreBluetooth

protocol PeripheralControllerDelegate {
    func getNewCharacteristicValue() -> NSData?
}

class PeripheralController : NSObject, CBPeripheralManagerDelegate {
    
    var delegate: PeripheralControllerDelegate
    var peripheralManager: CBPeripheralManager
    var characteristic: CBMutableCharacteristic!
    var group: dispatch_group_t?
    
    let serviceUUID = CBUUID(string: kServiceUUID)
    let characteristicUUID = CBUUID(string: kCharacteristicUUID)
    private let timeout = 5.0
    
    init(delegate: PeripheralControllerDelegate) {
        self.delegate = delegate
        peripheralManager = CBPeripheralManager(delegate: nil, queue: dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0))
    }
    
    func start() {
        group = dispatch_group_create()
        dispatch_group_enter(group!)
        peripheralManager.delegate = self
        
        let status = dispatch_group_wait(group!, dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * Double(NSEC_PER_SEC))));
        
        if (status != 0) {
            assertionFailure("Peripheral fail to start.")
        }
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
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceUUID]])
        if group != nil {
            dispatch_group_leave(group!)
            group = nil
        }
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
        guard let updatedValue = delegate.getNewCharacteristicValue() else {
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
        guard let updatedValue = delegate.getNewCharacteristicValue() else {
            return
        }
        let didSendValue = peripheralManager.updateValue(updatedValue, forCharacteristic: self.characteristic, onSubscribedCentrals: nil)
        if !didSendValue {
            print("waiting for resend …")
        }
    }
    
    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
        // resend
        guard let updatedValue = delegate.getNewCharacteristicValue() else {
            return
        }
        let didSendValue = peripheralManager.updateValue(updatedValue, forCharacteristic: self.characteristic, onSubscribedCentrals: nil)
        if !didSendValue {
            assertionFailure("Fail to send value update.")
        }
    }
}
