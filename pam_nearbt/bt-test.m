//
//  main.m
//  nearbt-osx
//
//  Created by guoc on 13/03/2016.
//  Copyright © 2016 guoc. All rights reserved.
//

#include <pwd.h>

#import <Foundation/Foundation.h>

#import "Constants.h"
#import "Log.h"
#import "NBTCentralController.h"

extern int
check_password(const char*secret, const char*password);

extern const char *
get_valid_secret_path(const char *path, const char *homedir);

const int testMinimumRSSI = -50;
const int testAllowedTimeout = 10;
const char *testSecretPath = "~/Downloads/secret.txt";
const BOOL testDebug = YES;

int main(int argc, const char * argv[]) {
    
    @autoreleasepool {
        
        // Get peripheral UUID
        
        NSString *peripheralConfigurationFilePath = kLocalPeripheralConfigurationFilePath.stringByExpandingTildeInPath;
        if (![[NSFileManager defaultManager] fileExistsAtPath:peripheralConfigurationFilePath]) {
            peripheralConfigurationFilePath = kGlobalPeripheralConfigurationFilePath;
        }
        if (![[NSFileManager defaultManager] fileExistsAtPath:peripheralConfigurationFilePath]) {
            Log(YES, @"Peripheral configuration file %@ not exist", peripheralConfigurationFilePath);
            return EXIT_FAILURE;
        }
        NSString *uuidString = [NSString stringWithContentsOfFile:peripheralConfigurationFilePath encoding:NSUTF8StringEncoding error:nil];
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
        
        // Read value from peripheral

        NBTCentralController *controller = [[NBTCentralController alloc] init];
        controller.debug = testDebug;
        NSData *value = [controller readValueForCharacteristicUUID:[CBUUID UUIDWithString:kCharacteristicUUID] ofServiceUUID:[CBUUID UUIDWithString:kServiceUUID] ofPeripheralUUID:uuid withMinimumRSSI:[NSNumber numberWithInt:(testMinimumRSSI)] withTimeout:testAllowedTimeout];
        if (value == nil) {
            Log(YES, @"Fail to read TOTP.");
            return EXIT_FAILURE;
        }
        Log(testDebug, @"Read value: %@", value);
        
        // Read secret from local files
        
        const char *secret_path = get_valid_secret_path(testSecretPath, "/Users/guoc");
        NSString *secretPath = [NSString stringWithCString:secret_path encoding:NSUTF8StringEncoding];
        if (![[NSFileManager defaultManager] fileExistsAtPath:secretPath]) {
            Log(YES, @"%@ not exist", secretPath);
            return EXIT_FAILURE;
        }
        const char *secret = [[[NSString stringWithContentsOfFile:secretPath encoding:NSUTF8StringEncoding error:nil] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] UTF8String];
        if (!secret) {
            Log(YES, @"Fail to read secret file.");
            return EXIT_FAILURE;
        }
        
        // Convert value to password and check its validity with secret
        
        const char *password = [[[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding] UTF8String];
        int passwordMatched = check_password(secret, password);
        if (passwordMatched == 0) {
            Log(YES, @"TOTP matched.");
            return EXIT_SUCCESS;
        } else {
            Log(YES, @"TOTP not matched.");
            return EXIT_FAILURE;
        }
    }
    
    return 0;
}
