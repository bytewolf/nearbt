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

@property (nonatomic) BOOL debug;

- (nullable NSData *)readValueForCharacteristicUUID:(nonnull CBUUID *)characteristicUUID ofServiceUUID:(nonnull CBUUID *)serviceUUID ofPeripheralUUID:(nonnull NSUUID *)peripheralUUID withMinimumRSSI:(nullable NSNumber *)rssi withTimeout:(NSTimeInterval)timeout;

@end
