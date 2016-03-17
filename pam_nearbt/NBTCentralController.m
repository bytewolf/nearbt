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
@property (nonatomic) CBUUID * serviceUUID;
@property (nonatomic) CBUUID * characteristicUUID;
@end

@implementation NBTCentralController

- (instancetype)initWithMinimumRSSI:(NSNumber *)rssi timeout:(NSUInteger)timeout {
    self = [super init];
    if (self) {
        self.minimumRSSI = rssi;
        self.allowedTimeout = timeout;
        self.valueData = nil;
    }
    return self;
}

- (NSData *)readValueForCharacteristicUUID:(CBUUID *)characteristicUUID ofServiceUUID:(CBUUID *)serviceUUID {
    self.characteristicUUID = characteristicUUID;
    self.serviceUUID = serviceUUID;
    
    self.group = dispatch_group_create();
    dispatch_group_enter(self.group);
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)];
    
    long status = dispatch_group_wait(self.group, dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC * self.allowedTimeout));

    self.centralManager.delegate = nil;
    
    NSLog(@"dispatch_group_wait return status: %ld", status);
    NSLog(@"valueData: %@", self.valueData);
    
    if (status != 0) {
        NSLog(@"dispatch_group_wait timeout.");
        return nil;
    }
    
    return self.valueData;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"Central manager did update state: %ld", central.state);
    if (central.state != CBCentralManagerStatePoweredOn) {
        return;
    }
    [central scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    self.targetPeripheral = peripheral;
    NSLog(@"Central manager did discover peripheral: %@", peripheral);
    NSLog(@"                                   RSSI: %@", RSSI);
    if (RSSI.integerValue > -20 || RSSI.integerValue < self.minimumRSSI.integerValue) {
        return;
    }
    [central connectPeripheral:peripheral options:nil];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Central manager did connect peripheral: %@",peripheral);
    peripheral.delegate = self;
    [peripheral discoverServices:@[self.serviceUUID]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
        NSLog(@"Error: %@", error);
    NSLog(@"Central manager did discover services %@", peripheral.services);
    CBService *targetService = nil;
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:self.serviceUUID]) {
            targetService = service;
            [self.centralManager stopScan];
            break;
        }
    }
    if (targetService) {
        [peripheral discoverCharacteristics:@[self.characteristicUUID] forService:targetService];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error)
        NSLog(@"Error: %@", error);
    NSLog(@"Central manager did discover characteristics %@", service.characteristics);
    CBCharacteristic *targetCharacteristic = nil;
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:self.characteristicUUID]) {
            targetCharacteristic = characteristic;
            break;
        }
    }
    if (targetCharacteristic) {
        [peripheral readValueForCharacteristic:targetCharacteristic];
        [peripheral setNotifyValue:YES forCharacteristic:targetCharacteristic];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error)
        NSLog(@"Error: %@", error);
    self.valueData = characteristic.value;
    if (self.group) {
        dispatch_group_leave(self.group);
        self.group = nil;
    }
    return;
}

@end
