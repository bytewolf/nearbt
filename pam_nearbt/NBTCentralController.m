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
#import "oath.h"

@interface NBTCentralController ()
@property (nonatomic) NSNumber *minimumRSSI;
@property (nonatomic) NSUInteger allowedTimeout;
@property (nonatomic) CBPeripheral *targetPeripheral;
@property (nonatomic) CBCentralManager *centralManager;
@property (nonatomic) NSData *valueData;
@property (nonatomic) dispatch_group_t group;
@property (nonatomic) NSUUID * targetPeripheralUUID;
@property (nonatomic) CBUUID * targetServiceUUID;
@property (nonatomic) CBUUID * targetCharacteristicUUID;
@end

@implementation NBTCentralController

- (instancetype)initWithMinimumRSSI:(NSNumber *)rssi timeout:(NSUInteger)timeout {
    NSLog(@"{{{ NBTCentralController init.");
    self = [super init];
    if (self) {
        self.minimumRSSI = rssi;
        self.allowedTimeout = timeout;
        self.targetPeripheral = nil;
        self.valueData = nil;
    }
    NSLog(@"}}} End of NBTCentralController init.");
    return self;
}

- (NSData *)readValueForCharacteristicUUID:(CBUUID *)characteristicUUID ofServiceUUID:(CBUUID *)serviceUUID ofPeripheralUUID:(NSUUID *)peripheralUUID {
    NSLog(@"{{{ Trying reading value …");
    self.targetCharacteristicUUID = characteristicUUID;
    self.targetServiceUUID = serviceUUID;
    self.targetPeripheralUUID = peripheralUUID;
    
    self.group = dispatch_group_create();
    dispatch_group_enter(self.group);
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)];
    
    long status = dispatch_group_wait(self.group, dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC * self.allowedTimeout));

    NSData *result = self.valueData;
    
    [self cleanup];
    
    NSLog(@"dispatch_group_wait return status: %ld", status);
    
    if (status != 0) {
        NSLog(@"}}} dispatch_group_wait timeout.");
        return nil;
    }
    NSLog(@"}}} End of reading value.");
    return result;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"{{{ Central manager did update state: %ld", central.state);
    if (self.targetPeripheral) {
        NSLog(@"}}} Target peripheral has been founded, stop.");
        return;
    }
    if (central.state != CBCentralManagerStatePoweredOn) {
        return;
    }
    self.targetPeripheral = [central retrievePeripheralsWithIdentifiers:@[self.targetPeripheralUUID]].lastObject;
    if (self.targetPeripheral) {
        [central connectPeripheral:self.targetPeripheral options:nil];
    } else {
        [self cleanup];
    }
    NSLog(@"}}}");
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"{{{ Central manager did connect peripheral: %@", peripheral.name);
    peripheral.delegate = self;
    NSLog(@"}}} Try read RSSI");
    [peripheral readRSSI];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Fail to connect to %@: %@", peripheral, [error localizedDescription]);
    [self cleanup];
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    NSNumber *RSSI = peripheral.RSSI;
    NSLog(@"{{{ Peripheral did update RSSI, %@", RSSI);
    if (RSSI.integerValue > -15 || RSSI.integerValue < self.minimumRSSI.integerValue) {
        NSLog(@"}}} RSSI(%@) is invalid.", RSSI);
        [self cleanup];
        return;
    }
    NSLog(@"}}} Try discover the peripheral's services …");
    [peripheral discoverServices:@[self.targetServiceUUID]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@"{{{ Central manager did discover services %@", peripheral.services);
    if (error) {
        NSLog(@"}}} Error discovering services: %@", [error localizedDescription]);
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
        NSLog(@"Target service is found.\n");
        self.targetPeripheral = peripheral;
        [peripheral discoverCharacteristics:@[self.targetCharacteristicUUID] forService:targetService];
    } else {
        NSLog(@"}}} Target service is not found.");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"{{{ Central manager did discover characteristics %@", service.characteristics);
    if (error) {
        NSLog(@"}}} Error discovering characteristics: %@", [error localizedDescription]);
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
        NSLog(@"}}} Target characteristic is found, try reading and subscribing it.");
        [peripheral readValueForCharacteristic:targetCharacteristic];
        [peripheral setNotifyValue:YES forCharacteristic:targetCharacteristic];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"{{{ Peripheral did update value.");
    if (error) {
        NSLog(@"}}} Error did update value: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    self.valueData = characteristic.value;
    NSLog(@"}}} Get target characteristic value: %@", self.valueData);
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
