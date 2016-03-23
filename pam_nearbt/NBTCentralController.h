//
//  NBTCentralController.h
//  NearBT
//
//  Created by guoc on 13/03/2016.
//  Copyright © 2016 guoc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>

@interface NBTCentralController : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

- (instancetype)initWithMinimumRSSI: (NSNumber *)rssi timeout: (NSUInteger)timeout;
- (NSData *)readValueForCharacteristicUUID:(CBUUID *)characteristicUUID ofServiceUUID:(CBUUID *)serviceUUID ofPeripheralUUID:(NSUUID *)peripheralUUID;

@end
