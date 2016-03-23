//
//  ViewController.swift
//  NearBT
//
//  Created by guoc on 13/03/2016.
//  Copyright © 2016 guoc. All rights reserved.
//

import UIKit
import OneTimePassword

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var informationLabel: UILabel!
    @IBOutlet weak var setSecretButton: UIButton!
    @IBOutlet weak var enabledSwitch: UISwitch!
    @IBOutlet weak var availableWhenDeviceLockedSwitch: UISwitch!
    @IBOutlet weak var invisibleTextField: UITextField! {
        didSet {
            invisibleTextField.delegate = self
        }
    }
    
    @IBAction func availableWhenDeviceLockedSwitchValueChanged(sender: UISwitch) {
        UserDefaults.sharedUserDefaults.availableWhenDeviceLocked = availableWhenDeviceLockedSwitch.on
        resetViewAnimated(true)
        OTPManager.sharedManager.resaveSecret()
    }
    
    @IBAction func setSecretButtonPressed() {
        invisibleTextField.becomeFirstResponder()
    }
    
    @IBAction func enabledSwitchValueChanged() {
        UserDefaults.sharedUserDefaults.enabled = enabledSwitch.on
        resetViewAnimated(true)
        if enabledSwitch.on {
            PeripheralController.sharedController.start()
        } else {
            PeripheralController.sharedController.stop()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(handleBluetoothStateChanged(_:)), name: notificationKeyBluetoothStateChanged, object: nil)
    }
    
    func handleBluetoothStateChanged(notification: NSNotification) {
        resetViewAnimated(true)
    }
    
    func resetViewAnimated(animated: Bool) {
        guard isViewLoaded() else {
            return
        }
        
        let hasSetSecret = OTPManager.sharedManager.hasSetSecret
        let enabled = UserDefaults.sharedUserDefaults.enabled
        enabledSwitch.setOn(enabled, animated: animated)
        enabledSwitch.enabled = hasSetSecret
        
        let availableWhenDeviceLocked = UserDefaults.sharedUserDefaults.availableWhenDeviceLocked
        availableWhenDeviceLockedSwitch.setOn(availableWhenDeviceLocked, animated: animated)
        availableWhenDeviceLockedSwitch.enabled = enabled
        
        switch PeripheralController.sharedController.bluetoothState {
        case .Unknown:
            informationLabel.text = "Waiting bluetooth …"
            if UserDefaults.sharedUserDefaults.enabled == false {
                informationLabel.text = "Please turn on \"Enabled\" switch."
            }
            if OTPManager.sharedManager.hasSetSecret == false {
                informationLabel.text = "Please set secret."
            }
        case .Unsupported:
            informationLabel.text = "Bluetooth low energy is not supported."
        case .PowerOff:
            informationLabel.text = "Please turn on Bluetooth."
        case .PairingRequired:
            informationLabel.text = "Pairing required. This will be done automatically when you run pam_nearbt-setup on your Mac."
        case .Ready:
            if hasSetSecret {
                var text = "Tap switch to turn on/off."
                if enabled {
                    text = "Ready."
                }
                informationLabel.text = text
            } else {
                informationLabel.text = "Set secret before turning on."
            }
        }
        
        if invisibleTextField.editing {
            informationLabel.text = "- Type secret and end with return.\n"
                + "- Secret and your typing will not be displayed.\n"
                + "- Typing return directly makes no change."
        }
        
        invisibleTextField.text = nil
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        resetViewAnimated(false)
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        resetViewAnimated(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        invisibleTextField.resignFirstResponder()
        guard let secretString = textField.text else {
            resetViewAnimated(true)
            return true
        }
        guard !secretString.isEmpty else {
            resetViewAnimated(true)
            informationLabel.text = "Cancelled."
            return true
        }
        OTPManager.sharedManager.secret = secretString.dataUsingEncoding(NSUTF8StringEncoding)!
        resetViewAnimated(true)
        informationLabel.text = "Secret changed."
        return true
    }

}

