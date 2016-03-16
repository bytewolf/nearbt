#include <unistd.h>
#include <security/pam_appl.h>
#include "oath.h"

#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/IOBluetoothUtilities.h>

#import "Constants.h"
#import "NBTCentralController.h"

#define DEFAULT_MINIMUM_RSSI (-50)
#define ALLOWED_TIMEOUT (5)

struct cfg
{
    BluetoothDeviceAddress bt_addr;
    BluetoothHCIRSSIValue min_rssi;
    const char *secret_path;
    const char *run_if_success;
    const char *run_if_fail;
    const char *run_always;
};

static void
parse_cfg (int flags, int argc, const char *argv[], struct cfg *cfg)
{
    memset (cfg, 0, sizeof(struct cfg));
    cfg->min_rssi = DEFAULT_MINIMUM_RSSI;
    cfg->secret_path = "/usr/local/etc/pam_nearbt/secret";
    for (int i = 0; i < argc; i++)
    {
        if (strncmp (argv[i], "bt_addr=", 8) == 0)
        {
            NSString *addressString = [NSString stringWithUTF8String:(argv[i] + 8)];
            IOBluetoothNSStringToDeviceAddress(addressString, &(cfg->bt_addr));
        }

        if (strncmp (argv[i], "min_rssi=", 9) == 0)
        {
            sscanf (argv[i], "min_rssi=%hhd", &cfg->min_rssi);
        }
        
        if (strncmp (argv[i], "secret_path=", 12) == 0)
        {
            cfg->secret_path = argv[i] + 12;
        }

        if (strncmp (argv[i], "run_if_success=", 15) == 0)
        {
            cfg->run_if_success = argv[i] + 15;
        }

        if (strncmp (argv[i], "run_if_fail=", 12) == 0)
        {
            cfg->run_if_fail = argv[i] + 12;
        }

        if (strncmp (argv[i], "run_always=", 11) == 0)
        {
            cfg->run_always = argv[i] + 11;
        }
    }
}

static void
run(const char *file_path)
{
    if (file_path && access(file_path, F_OK) != -1)
    {
        NSString *filePath = [NSString stringWithUTF8String:file_path];
        [NSTask launchedTaskWithLaunchPath:filePath arguments:@[]];
    }
}

extern int
check_password(const char*secret, const char*password) {
    time_t currentTime = time(NULL);
    size_t window = 3;
    oath_init();
    int pos = oath_totp_validate(secret, strlen(secret), currentTime, 30, 0, window, password);
    oath_done();
    if (pos == OATH_INVALID_OTP || pos < 0 || pos >= window) {
        return -1;
    } else {
        return 0;
    }
    return 0;
}

int
pam_sm_setcred(pam_handle_t *pamh, int flags,
                   int argc, const char *argv[])
{
    return PAM_SUCCESS;
}

int
pam_sm_authenticate(pam_handle_t *pamh, int flags,
    int argc, const char *argv[])
{
    struct cfg cfg_st;
    struct cfg *cfg = &cfg_st;
    parse_cfg (flags, argc, argv, cfg);

    run(cfg->run_always);

    @autoreleasepool {
        
        NBTCentralController *controller = [[NBTCentralController alloc] initWithMinimumRSSI:[NSNumber numberWithInt:cfg->min_rssi] allowedTimeout:ALLOWED_TIMEOUT];
        
        NSData *value = [controller readValueForCharacteristicUUID:[CBUUID UUIDWithString:kCharacteristicUUID] ofServiceUUID:[CBUUID UUIDWithString:kServiceUUID]];
        if (value == nil) {
            NSLog(@"Fail to read value from peripheral");
            run(cfg->run_if_fail);
            return (PAM_AUTH_ERR);
        }
        NSLog(@"Read value: %@", value);
        
        NSString *secretPath = [NSString stringWithCString:cfg->secret_path encoding:NSUTF8StringEncoding];
        const char *secret = [[[NSString stringWithContentsOfFile:secretPath encoding:NSUTF8StringEncoding error:nil] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] UTF8String];
        if (secret == nil) {
            NSLog(@"Fail to read secret file %@", secretPath);
            run(cfg->run_if_fail);
            return (PAM_AUTH_ERR);
        }
        
        const char *password = [[[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding] UTF8String];
        int passwordMatched = check_password(secret, password);
        NSLog(@"Password matched: %d", passwordMatched);
        
        if (passwordMatched == 0) {
            run(cfg->run_if_success);
            return (PAM_SUCCESS);
        } else {
            run(cfg->run_if_fail);
            return (PAM_AUTH_ERR);
        }
    }
}
