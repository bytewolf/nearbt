//
//  main.m
//  nearbt-osx
//
//  Created by guoc on 13/03/2016.
//  Copyright © 2016 guoc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"
#import "NBTCentralController.h"

extern int
check_password(const char*secret, const char*password);

const int testMinimumRSSI = -50;
const int testAllowedTimeout = 5;
const char *testSecretPath = "/usr/local/etc/pam_nearbt/secret";

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NBTCentralController *controller = [[NBTCentralController alloc] initWithMinimumRSSI:[NSNumber numberWithInt:(testMinimumRSSI)] allowedTimeout:testAllowedTimeout];
        NSData *value = [controller readValueForCharacteristicUUID:[CBUUID UUIDWithString:kCharacteristicUUID] ofServiceUUID:[CBUUID UUIDWithString:kServiceUUID]];
        NSString *secretPath = [NSString stringWithCString:testSecretPath encoding:NSUTF8StringEncoding];
        const char *secret = [[[NSString stringWithContentsOfFile:secretPath encoding:NSUTF8StringEncoding error:nil] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] UTF8String];
        NSLog(@"Read value: %@", value);
        const char *password = [[[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding] UTF8String];
        int passwordMatched = check_password(secret, password);
        NSLog(@"Password matched: %d", passwordMatched);
        dispatch_main();
    }
    return 0;
}
