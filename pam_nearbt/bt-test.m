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
#import "NBTCentralController.h"

extern int
check_password(const char*secret, const char*password);

extern const char *
get_valid_secret_path(const char *path, const char *homedir);

const int testMinimumRSSI = -80;
const int testAllowedTimeout = 10;
const char *testSecretPath = "~/Downloads/secret.txt";

int main(int argc, const char * argv[]) {
    
    @autoreleasepool {
        
        NBTCentralController *controller = [[NBTCentralController alloc] initWithMinimumRSSI:[NSNumber numberWithInt:(testMinimumRSSI)] timeout:testAllowedTimeout];
        NSData *value = [controller readValueForCharacteristicUUID:[CBUUID UUIDWithString:kCharacteristicUUID] ofServiceUUID:[CBUUID UUIDWithString:kServiceUUID]];
        const char *secret_path = get_valid_secret_path(testSecretPath, "/Users/guoc");
        NSString *secretPath = [NSString stringWithCString:secret_path encoding:NSUTF8StringEncoding];
        if (![[NSFileManager defaultManager] fileExistsAtPath:secretPath]) {
            NSLog(@"%@ not exist", secretPath);
            return -1;
        }
        const char *secret = [[[NSString stringWithContentsOfFile:secretPath encoding:NSUTF8StringEncoding error:nil] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] UTF8String];
        if (!secret) {
            NSLog(@"Fail to read secret file.");
            return -1;
        }
        NSLog(@"Read value: %@", value);
        const char *password = [[[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding] UTF8String];
        int passwordMatched = check_password(secret, password);
        NSLog(@"Password matched: %d", passwordMatched);
        
    }
    return 0;
}
