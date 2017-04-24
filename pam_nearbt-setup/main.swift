//
//  main.swift
//  pam_nearbt-setup
//
//  Created by guoc on 23/03/2016.
//  Copyright © 2016 guoc. All rights reserved.
//

import Foundation
import CoreBluetooth

extension FileManager {
    
    func createConfigurationFileAtPath(_ path: String, contents data: Data?) -> Bool {
        guard let directoryPath = NSURL(fileURLWithPath: path, isDirectory: false).deletingLastPathComponent?.path else {
            fatalError("Fail to get directory of \(path)")
        }
        do {
            try createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            fatalError("Fail to create directory of \(path)")
        }
        let created = createFile(atPath: path, contents: data, attributes: [FileAttributeKey.posixPermissions.rawValue:NSNumber(value: 0400 as Int16)])
        return created
    }

}

class CentralDelegate: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var valueReadFromPeripheral = DispatchSemaphore(value: 0)
    var targetPeripheral: CBPeripheral?
    
    let serviceUUID = CBUUID(string: kServiceUUID)
    let characteristicUUID = CBUUID(string: kCharacteristicUUID)
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: [serviceUUID], options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripheral.delegate = self
        targetPeripheral = peripheral
        central.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Fail to connect peripheral: \(error?.localizedDescription ?? "no error message")")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.last, service.uuid == serviceUUID else {
            print("Target service is not found.")
            return
        }
        peripheral.discoverCharacteristics([characteristicUUID], for:service)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristic = service.characteristics?.last, characteristic.uuid == characteristicUUID else {
            print("Target characteristic is not found.")
            return
        }
        peripheral.readValue(for: characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            fatalError("Setup failure: \(error.localizedDescription)")
        }
        
        valueReadFromPeripheral.signal()
        
        return
    }
    
}

func typeReturnToContinue() {
    print()
    print("Type return to continue …")
    if readLine() != nil {
        return
    } else {
        exit(EXIT_FAILURE)
    }
}

func isSIPEnabled() -> Bool {
    let csrutilPath = "/usr/bin/csrutil"
    if FileManager.default.fileExists(atPath: csrutilPath) == false {
        return false
    }
    let pipe = Pipe()
    let task: Process = {
        let task = Process()
        task.launchPath = csrutilPath
        task.arguments = ["status"]
        task.standardOutput = pipe
        return task
    }()
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let output = String(data: data, encoding: String.Encoding.utf8) else {
        fatalError("Fail to check System Integrity Protection status.")
    }
    let isEnabled = output.contains("enabled")
    return isEnabled
}

func printHelp() {
    print("Usage:")
    print()
    print("\t" + "pam_nearbt-setup")
    print("\t\t" + "Start setup.")
    print()
    print("\t" + "pam_nearbt-setup parameters")
    print("\t\t" + "Show parameters for PAM configuration.")
    print()
}

func printParameters() {
    print("Parameters:")
    print()
    print("\t" + "debug")
    print("\t\t" + "Enable debug message output (pam_nearbt log: …).")
    print("\t\t" + "Not set by default.")
    print()
    print("\t" + "min_rssi=<between -128 and -15>")
    print("\t\t" + "Minimum RSSI (received signal strength indicator).")
    print("\t\t" + "Higher values reduce the valid scope of iOS devices.")
    print("\t\t" + "-50 by default")
    print()
    print("\t" + "timeout=<unsigned integer>")
    print("\t\t" + "Allowed timeout. Authentication will fail after specific seconds.")
    print("\t\t" + "5 (seconds) by default")
    print()
    print("\t" + "secret_path=<absolute path>")
    print("\t\t" + "Specify secret file path.")
    print("\t\t" + "~/.config/pam_nearbt/secret and /usr/local/etc/pam_nearbt/secret are applied if secret_path is not specified.")
    print()
    print("\t" + "run_if_success=<absolute path>")
    print("\t\t" + "Specify a script which will be run if authentication succeeds.")
    print()
    print("\t" + "run_if_fail=<absolute path>")
    print("\t\t" + "Specify a script which will be run if authentication fails.")
    print()
    print("\t" + "run_always=<absolute path>")
    print("\t\t" + "Specify a script which will be run when authentication begins.")
    print()
}

func installPAM() {
    print("(1/3) Install PAM")
    print()
    let pamSourcePath = "/usr/local/lib/security/pam_nearbt.so"
    let pamTargetPath = "/usr/lib/pam/pam_nearbt.so"
    if FileManager.default.fileExists(atPath: pamTargetPath) {
        print("Already installed.")
        return
    }
    let command_ln = "ln -fs \(pamSourcePath) \(pamTargetPath)"
    let command_chown = "chown -h root:wheel \(pamTargetPath)"
    let command_chmod = "chmod -h 444 \(pamTargetPath)"
    print("The following commands will create a symbolic link \(pamTargetPath) to \(pamSourcePath) and set permissions and ownership.")
    print("```")
    print(command_ln)
    print(command_chown)
    print(command_chmod)
    print("```")
    typeReturnToContinue()
    if isSIPEnabled() {
        print("System Integrity Protection (SIP) is enabled on your OS X.")
        print("To install files in /usr/, you have to turn off SIP.")
        print("Follow the instructions below to turn off SIP, and then relaunch this setup.")
        print("1. Shut down your computer.")
        print("2. Start your computer from Recovery (hold down Command+R at startup).")
        print("3. Launch Terminal under Utilities in menu bar.")
        print("4. Type \"csrutil disable\" to turn off SIP.")
        print("   (After installation, remember to turn on SIP for system security by typing \"csrutil enable\")")
        print("5. Restart your computer.")
        typeReturnToContinue()
        exit(EXIT_FAILURE)
    }
    print("To allow these commands, type your password in the authentication dialog.")
    typeReturnToContinue()
    let script = "do shell script \"\(command_ln); \(command_chown); \(command_chmod)\" with administrator privileges"
    let appleScript = NSAppleScript(source: script)
    var errorInfo: NSDictionary? = NSDictionary()
    guard appleScript?.executeAndReturnError(&errorInfo) != nil else {
        print("Fail to install pam_nearbt.")
        guard let errorInfo = errorInfo else {
            fatalError("Fail to read error information.")
        }
        guard let errorNumber = errorInfo[NSAppleScript.errorNumber] as? NSNumber else {
            fatalError("Fail to read error number.")
        }
        switch errorNumber.intValue {
        case -128:
            print("Canceled.")
            exit(EXIT_FAILURE)
        default:
            print("Please send the following error information to guochen42+nearbt@gmail.com, thank you.")
            print(errorInfo)
            exit(EXIT_FAILURE)
        }
    }
    print("Success.")
}

func setupPeripheral() {
    print("(2/3) Setup Peripheral")
    print()
    print("Launch NearBT on your iOS device, set secret if necessary and turn on \"Enabled\".")
    print("Bluetooth pairing may be requested.")
    typeReturnToContinue()
    
    let delegate = CentralDelegate()
    let manager = CBCentralManager(delegate: delegate, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive))
    
    _ = delegate.valueReadFromPeripheral.wait(timeout: DispatchTime.distantFuture)
    
    guard let targetPeripheral = delegate.targetPeripheral else {
        manager.delegate = nil
        fatalError("Fail to get peripheral UUID.")
    }
    let peripheralConfigurationFilePath = NSString(string:kGlobalPeripheralConfigurationFilePath).expandingTildeInPath
    if FileManager.default.fileExists(atPath: peripheralConfigurationFilePath) {
        print("\(peripheralConfigurationFilePath) exists, overwrite? (y/n) ", terminator:"")
        if let response = readLine(strippingNewline: true), response != "y" && response != "Y" {
            manager.delegate = nil
            print("Canceled.")
            return
        }
    }
    
    let created = FileManager.default.createConfigurationFileAtPath(peripheralConfigurationFilePath, contents: targetPeripheral.identifier.uuidString.data(using: String.Encoding.utf8))
    if !created {
        print("Fail to create peripheral at \(peripheralConfigurationFilePath)")
        exit(EXIT_FAILURE)
    }
    manager.delegate = nil
    print("Success.")
    return
}

func setupSecret() {
    print("(3/3) Setup Secret")
    print()
    if FileManager.default.fileExists(atPath: kDefaultGlobalSecretFilePath) {
        print("\(kDefaultGlobalSecretFilePath) exists, overwrite? (y/n) ", terminator:"")
        if let response = readLine(strippingNewline: true), response != "y" && response != "Y" {
            print("Canceled.")
            return
        }
    }
    var secret = ""
    repeat {
        secret = String(cString: getpass("Please enter your secret: ")) 
    } while secret.isEmpty
    let created = FileManager.default.createConfigurationFileAtPath(kDefaultGlobalSecretFilePath, contents: secret.data(using: String.Encoding.utf8))
    if !created {
        print("Fail to create secret at \(kDefaultGlobalSecretFilePath)")
        exit(EXIT_FAILURE)
    }
    print("Success.")
}

func setupPAM() {
    print("Now you could add pam_nearbt.so in some files under /etc/pam.d/")
    print("Restarting may be required.")
    print()
    print("e.g.")
    print("Add the following line at the beginning of /etc/pam.d/screensaver, so that you can unlock screensaver without password by using NearBT.")
    print("auth       sufficient     pam_nearbt.so min_rssi=-55 timeout=10")
    print("Note: this example is only for testing. It may increase security risks.")
}

// MARK: - main() -

if CommandLine.argc == 2 {
    switch CommandLine.arguments[1] {
    case "parameters", "parameter", "parametres", "parametre", "params", "param":
        printParameters()
        exit(EXIT_SUCCESS)
    case "-h", "help", "-help", "--help":
        printHelp()
        exit(EXIT_SUCCESS)
    default:
        print("Invalid command.")
        printHelp()
        exit(EXIT_FAILURE)
    }
}

guard CommandLine.argc == 1 else {
    print("Invalid command.")
    printHelp()
    exit(EXIT_FAILURE)
}

installPAM()
typeReturnToContinue()

setupPeripheral()
typeReturnToContinue()

setupSecret()
typeReturnToContinue()

print("Setup finished.")
print()

setupPAM()
