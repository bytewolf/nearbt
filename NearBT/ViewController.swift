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
    
    @IBAction func availableWhenDeviceLockedSwitchValueChanged(_ sender: UISwitch) {
        UserDefaults.sharedUserDefaults.availableWhenDeviceLocked = availableWhenDeviceLockedSwitch.isOn
        resetViewAnimated(true)
        OTPManager.sharedManager.resaveSecret()
    }
    
    @IBAction func setSecretButtonPressed() {
        invisibleTextField.becomeFirstResponder()
    }
    
    @IBAction func enabledSwitchValueChanged() {
        UserDefaults.sharedUserDefaults.enabled = enabledSwitch.isOn
        resetViewAnimated(true)
        if enabledSwitch.isOn {
            PeripheralController.sharedController.start()
        } else {
            PeripheralController.sharedController.stop()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(handleBluetoothStateChanged(_:)), name: NSNotification.Name(rawValue: notificationKeyBluetoothStateChanged), object: nil)
    }
    
    func handleBluetoothStateChanged(_ notification: Notification) {
        resetViewAnimated(true)
    }
    
    func resetViewAnimated(_ animated: Bool) {
        guard isViewLoaded else {
            return
        }
        
        let hasSetSecret = OTPManager.sharedManager.hasSetSecret
        let enabled = UserDefaults.sharedUserDefaults.enabled
        enabledSwitch.setOn(enabled, animated: animated)
        enabledSwitch.isEnabled = hasSetSecret
        
        let availableWhenDeviceLocked = UserDefaults.sharedUserDefaults.availableWhenDeviceLocked
        availableWhenDeviceLockedSwitch.setOn(availableWhenDeviceLocked, animated: animated)
        availableWhenDeviceLockedSwitch.isEnabled = enabled
        
        switch PeripheralController.sharedController.bluetoothState {
        case .unknown:
            informationLabel.text = "Waiting bluetooth …"
            if UserDefaults.sharedUserDefaults.enabled == false {
                informationLabel.text = "Please turn on \"Enabled\" switch."
            }
            if OTPManager.sharedManager.hasSetSecret == false {
                informationLabel.text = "Please set secret."
            }
        case .unsupported:
            informationLabel.text = "Bluetooth low energy is not supported."
        case .powerOff:
            informationLabel.text = "Please turn on Bluetooth."
        case .pairingRequired:
            informationLabel.text = "Pairing required. This will be done automatically when you run pam_nearbt-setup on your Mac."
        case .ready:
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
        
        if invisibleTextField.isEditing {
            informationLabel.text = "- Type secret and end with return.\n"
                + "- Secret and your typing will not be displayed.\n"
                + "- Typing return directly makes no change."
        }
        
        invisibleTextField.text = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetViewAnimated(false)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        resetViewAnimated(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
        OTPManager.sharedManager.secret = secretString.data(using: String.Encoding.utf8)!
        resetViewAnimated(true)
        informationLabel.text = "Secret changed."
        return true
    }

}

