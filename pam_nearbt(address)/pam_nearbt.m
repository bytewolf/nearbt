#include <unistd.h>
#include <security/pam_appl.h>

#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/IOBluetoothUtilities.h>

#define DEFAULT_MINIMUM_RSSI (-50)

struct cfg
{
    BluetoothDeviceAddress bt_addr;
    BluetoothHCIRSSIValue min_rssi;
    const char *run_if_success;
    const char *run_if_fail;
    const char *run_always;
};

static void
parse_cfg (int flags, int argc, const char *argv[], struct cfg *cfg)
{
    memset (cfg, 0, sizeof(struct cfg));
    cfg->min_rssi = DEFAULT_MINIMUM_RSSI;
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

int
pam_sm_authenticate(pam_handle_t *pamh, int flags,
    int argc, const char *argv[])
{
    struct cfg cfg_st;
    struct cfg *cfg = &cfg_st;
    parse_cfg (flags, argc, argv, cfg);

    run(cfg->run_always);

    IOBluetoothDevice *device = [IOBluetoothDevice deviceWithAddress:&(cfg->bt_addr)];
    [device openConnection];
    BluetoothHCIRSSIValue rssi = [device rawRSSI];

    if (rssi != 127 && rssi >= cfg->min_rssi)
    {
        run(cfg->run_if_success);
        return (PAM_SUCCESS);
    }
    else
    {
        run(cfg->run_if_fail);
        return (PAM_AUTH_ERR);
    }
}
