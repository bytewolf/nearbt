//
//  NBTCentralController.m
//  NearBT
//
//  Created by guoc on 13/03/2016.
//  Copyright © 2016 guoc. All rights reserved.
//

#import "NBTCentralController.h"

#import <time.h>

#import "../Constants.h"
#import "Log.h"
#import "oath.h"

@interface NBTCentralController ()
@property (nonatomic) NSNumber *minimumRSSI;
@property (nonatomic) CBPeripheral *targetPeripheral;
@property (nonatomic) CBCentralManager *centralManager;
@property (nonatomic) NSData *valueData;
@property (nonatomic) dispatch_group_t group;
@property (nonatomic) NSUUID * targetPeripheralUUID;
@property (nonatomic) CBUUID * targetServiceUUID;
@property (nonatomic) CBUUID * targetCharacteristicUUID;
@end

@implementation NBTCentralController

- (nullable NSData *)readValueForCharacteristicUUID:(nonnull CBUUID *)characteristicUUID ofServiceUUID:(nonnull CBUUID *)serviceUUID ofPeripheralUUID:(nonnull NSUUID *)peripheralUUID withMinimumRSSI:(nullable NSNumber *)rssi withTimeout:(NSTimeInterval)timeout {
    Log(self.debug, @"{{{ Trying reading value …");
    self.targetCharacteristicUUID = characteristicUUID;
    self.targetServiceUUID = serviceUUID;
    self.targetPeripheralUUID = peripheralUUID;
    self.minimumRSSI = rssi;
    
    self.group = dispatch_group_create();
    dispatch_group_enter(self.group);
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)];
    
    long status = dispatch_group_wait(self.group, dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC * timeout));

    NSData *result = self.valueData;
    
    [self cleanup];
    
    Log(self.debug, @"dispatch_group_wait return status: %ld", status);
    
    if (status != 0) {
        Log(self.debug, @"}}} dispatch_group_wait timeout.");
        return nil;
    }
    Log(self.debug, @"}}} End of reading value.");
    return result;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    Log(self.debug, @"{{{ Central manager did update state: %ld", central.state);
    if (self.targetPeripheral) {
        Log(self.debug, @"}}} Target peripheral has been founded, stop.");
        return;
    }
    if (central.state != CBCentralManagerStatePoweredOn) {
        Log(self.debug, @"}}}");
        return;
    }
    self.targetPeripheral = [central retrievePeripheralsWithIdentifiers:@[self.targetPeripheralUUID]].lastObject;
    if (self.targetPeripheral) {
        [central connectPeripheral:self.targetPeripheral options:nil];
    } else {
        [self cleanup];
    }
    Log(self.debug, @"}}}");
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    Log(self.debug, @"{{{ Central manager did connect peripheral: %@", peripheral.name);
    peripheral.delegate = self;
    Log(self.debug, @"}}} Try read RSSI");
    [peripheral readRSSI];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    Log(YES, @"Fail to connect to %@: %@", peripheral, [error localizedDescription]);
    [self cleanup];
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    NSNumber *RSSI = peripheral.RSSI;
    Log(self.debug, @"{{{ Peripheral did update RSSI, %@", RSSI);
    if (RSSI.integerValue > -15 || RSSI.integerValue < self.minimumRSSI.integerValue) {
        Log(YES, @"RSSI(%@) is invalid.", RSSI);
        Log(self.debug, @"}}}", RSSI);
        [self cleanup];
        return;
    }
    Log(self.debug, @"}}} Try discover the peripheral's services …");
    [peripheral discoverServices:@[self.targetServiceUUID]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    Log(self.debug, @"{{{ Central manager did discover services %@", peripheral.services);
    if (error) {
        Log(YES, @"Error discovering services: %@", [error localizedDescription]);
        Log(self.debug, @"}}}");
        return;
    }
    CBService *targetService = nil;
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:self.targetServiceUUID]) {
            targetService = service;
            [self.centralManager stopScan];
            break;
        }
    }
    if (targetService) {
        Log(self.debug, @"}}} Target service is found.");
        [peripheral discoverCharacteristics:@[self.targetCharacteristicUUID] forService:targetService];
    } else {
        Log(YES, @"Target service is not found.");
        Log(self.debug, @"}}}");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    Log(self.debug, @"{{{ Central manager did discover characteristics %@", service.characteristics);
    if (error) {
        Log(YES, @"Error discovering characteristics: %@", [error localizedDescription]);
        Log(self.debug, @"}}}");
        [self cleanup];
        return;
    }
    CBCharacteristic *targetCharacteristic = nil;
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:self.targetCharacteristicUUID]) {
            targetCharacteristic = characteristic;
            break;
        }
    }
    if (targetCharacteristic) {
        Log(self.debug, @"}}} Target characteristic is found, try reading and subscribing it.");
        [peripheral readValueForCharacteristic:targetCharacteristic];
        [peripheral setNotifyValue:YES forCharacteristic:targetCharacteristic];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    Log(self.debug, @"{{{ Peripheral did update value.");
    if (error) {
        Log(YES, @"Error did update value: %@", [error localizedDescription]);
        Log(self.debug, @"}}}");
        [self cleanup];
        return;
    }
    self.valueData = characteristic.value;
    Log(self.debug, @"}}} Get target characteristic value: %@", self.valueData);
    if (self.group) {
        dispatch_group_leave(self.group);
        self.group = nil;
    }
    return;
}

- (void)cleanup {
    self.valueData = nil;
    
    if (self.targetPeripheral != nil && self.targetPeripheral.services != nil) {
        for (CBService *service in self.targetPeripheral.services) {
            if ([service.UUID isEqual:self.targetServiceUUID]) {
                if (service.characteristics != nil) {
                    for (CBCharacteristic *characteristic in service.characteristics) {
                        if ([characteristic.UUID isEqual:self.targetCharacteristicUUID]) {
                            if (characteristic.isNotifying) {
                                [self.targetPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                            }
                        }
                    }
                }
            }
        }
    }
    
    if (self.targetPeripheral && self.targetPeripheral.state != CBPeripheralStateDisconnected) {
        [self.centralManager cancelPeripheralConnection:self.targetPeripheral];
    }
    
    if (self.group) {
        dispatch_group_leave(self.group);
        self.group = nil;
    }
    
    self.centralManager.delegate = nil;
    self.centralManager = nil;
    
    self.targetPeripheral = nil;
}

@end
