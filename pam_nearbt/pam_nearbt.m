#include <unistd.h>
#include <security/pam_appl.h>
#include "oath.h"
#include <pwd.h>

#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/IOBluetoothUtilities.h>

#import "Constants.h"
#import "NBTCentralController.h"

#define DEFAULT_MINIMUM_RSSI (-50)
#define DEFAULT_TIMEOUT (5)

struct cfg
{
    BluetoothHCIRSSIValue min_rssi;
    unsigned timeout;
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
    cfg->timeout = DEFAULT_TIMEOUT;
    cfg->secret_path = "/usr/local/etc/pam_nearbt/secret";
    for (int i = 0; i < argc; i++)
    {
        if (strncmp (argv[i], "min_rssi=", 9) == 0)
        {
            sscanf (argv[i], "min_rssi=%hhd", &cfg->min_rssi);
        }
        
        if (strncmp (argv[i], "timeout=", 8) == 0)
        {
            sscanf (argv[i], "timeout=%u", &cfg->timeout);
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

static const char *
get_home_dir(pam_handle_t *pamh)
{
    const char *username = NULL;
    const char *homedir = NULL;
    pam_get_user(pamh, &username, NULL);
    if (username) {
        struct passwd *p = getpwnam(username);
        homedir = p->pw_dir;
    }
    return homedir;
}

extern const char *
get_valid_secret_path(const char *path, const char *homedir)
{
    NSString *secretPath = [NSString stringWithUTF8String:path];
    
    if ([secretPath hasPrefix:@"~"]) {
        if (!homedir) {
            NSLog(@"Fail to get current user directory, %@ is tried to be applied.", kDefaultGlobalSecretFilePath);
            return kDefaultGlobalSecretFilePath.UTF8String;
        }
        NSString *homeDirectory = [NSString stringWithUTF8String:homedir];
        secretPath = [homeDirectory stringByAppendingString:[secretPath substringFromIndex:1]];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:secretPath]) {
        return secretPath.UTF8String;
    } else {
        NSLog(@"%@ not found, %s is tried to be applied.", secretPath, kDefaultLocalSecretFilePath.UTF8String);
        secretPath = kDefaultLocalSecretFilePath;
    }
    
    if (!homedir) {
        NSLog(@"Fail to get current user directory, %@ is tried to be applied.", kDefaultGlobalSecretFilePath);
        return kDefaultGlobalSecretFilePath.UTF8String;
    }
    NSString *homeDirectory = [NSString stringWithUTF8String:homedir];
    secretPath = [homeDirectory stringByAppendingString:[secretPath substringFromIndex:1]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:secretPath]) {
        return secretPath.UTF8String;
    } else {
        NSLog(@"%@ not found, %@ is tried to be applied.", secretPath, kDefaultGlobalSecretFilePath);
        return kDefaultGlobalSecretFilePath.UTF8String;
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
    @autoreleasepool {
        
        NSLog(@"------ Start of pam_nearbt ------");
        
        struct cfg cfg_st;
        struct cfg *cfg = &cfg_st;
        parse_cfg (flags, argc, argv, cfg);
        
        run(cfg->run_always);
        
        const char *homedir = get_home_dir(pamh);
        const char *secret_path = get_valid_secret_path(cfg->secret_path, homedir);
        
        NSString *secretPath = [NSString stringWithCString:secret_path encoding:NSUTF8StringEncoding];
        if (![[NSFileManager defaultManager] fileExistsAtPath:secretPath]) {
            NSLog(@"Secret file %@ not exist", secretPath);
            run(cfg->run_if_fail);
            NSLog(@"------ End of pam_nearbt: %d ------", (PAM_AUTH_ERR));
            return (PAM_AUTH_ERR);
        }
        
        NSString *peripheralConfigurationFilePath = kLocalPeripheralConfigurationFilePath.stringByExpandingTildeInPath;
        if (![[NSFileManager defaultManager] fileExistsAtPath:peripheralConfigurationFilePath]) {
            peripheralConfigurationFilePath = kGlobalPeripheralConfigurationFilePath;
        }
        if (![[NSFileManager defaultManager] fileExistsAtPath:peripheralConfigurationFilePath]) {
            NSLog(@"Peripheral configuration file %@ not exist", peripheralConfigurationFilePath);
            run(cfg->run_if_fail);
            NSLog(@"------ End of pam_nearbt: %d ------", (PAM_AUTH_ERR));
            return (PAM_AUTH_ERR);
        }
        NSString *uuidString = [NSString stringWithContentsOfFile:peripheralConfigurationFilePath encoding:NSUTF8StringEncoding error:nil];
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
        
        NBTCentralController *controller = [[NBTCentralController alloc] init];
        
        NSData *value = [controller readValueForCharacteristicUUID:[CBUUID UUIDWithString:kCharacteristicUUID] ofServiceUUID:[CBUUID UUIDWithString:kServiceUUID] ofPeripheralUUID:uuid withMinimumRSSI:[NSNumber numberWithInt:cfg->min_rssi] withTimeout:cfg->timeout];
        if (value == nil) {
            NSLog(@"Fail to read value from peripheral");
            run(cfg->run_if_fail);
            NSLog(@"------ End of pam_nearbt: %d ------", (PAM_AUTH_ERR));
            return (PAM_AUTH_ERR);
        }
        NSLog(@"Read value: %@", value);
        
        const char *secret = [[[NSString stringWithContentsOfFile:secretPath encoding:NSUTF8StringEncoding error:nil] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] UTF8String];
        if (!secret) {
            NSLog(@"Fail to read secret file.");
            run(cfg->run_if_fail);
            NSLog(@"------ End of pam_nearbt: %d ------", (PAM_AUTH_ERR));
            return (PAM_AUTH_ERR);
        }
        if (secret == nil) {
            NSLog(@"Fail to read secret file %@", secretPath);
            run(cfg->run_if_fail);
            NSLog(@"------ End of pam_nearbt: %d ------", (PAM_AUTH_ERR));
            return (PAM_AUTH_ERR);
        }
        
        const char *password = [[[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding] UTF8String];
        int passwordMatched = check_password(secret, password);
        NSLog(@"Password matched: %d", passwordMatched);
        
        if (passwordMatched == 0) {
            run(cfg->run_if_success);
            NSLog(@"------ End of pam_nearbt: %d ------", (PAM_SUCCESS));
            return (PAM_SUCCESS);
        } else {
            run(cfg->run_if_fail);
            NSLog(@"------ End of pam_nearbt: %d ------", (PAM_AUTH_ERR));
            return (PAM_AUTH_ERR);
        }
    }
}
