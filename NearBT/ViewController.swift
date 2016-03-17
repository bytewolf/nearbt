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
    @IBOutlet weak var tokenCacheRequiredSwitch: UISwitch!
    @IBOutlet weak var invisibleTextField: UITextField! {
        didSet {
            invisibleTextField.delegate = self
        }
    }
    
    @IBAction func tokenCacheRequiredSwitchValueChanged(sender: UISwitch) {
        UserDefaults.sharedUserDefaults.tokenCacheRequired = tokenCacheRequiredSwitch.on
        resetViewAnimated(true)
    }
    
    @IBAction func setSecretButtonPressed() {
        invisibleTextField.becomeFirstResponder()
    }
    
    @IBAction func enabledSwitchValueChanged() {
        UserDefaults.sharedUserDefaults.enabled = enabledSwitch.on
        resetViewAnimated(true)
    }
    
    func resetViewAnimated(animated: Bool) {
        let enabled = UserDefaults.sharedUserDefaults.enabled
        enabledSwitch.setOn(enabled, animated: animated)
        
        let tokenCacheRequired = UserDefaults.sharedUserDefaults.tokenCacheRequired
        tokenCacheRequiredSwitch.setOn(tokenCacheRequired, animated: animated)
        
        let tokenRefExisted = (UserDefaults.sharedUserDefaults.tokenRef != nil)
        enabledSwitch.enabled = tokenRefExisted
        
        if invisibleTextField.editing {
            informationLabel.text = "- Type secret and end with return.\n"
                + "- Secret and your typing will not be displayed.\n"
                + "- Typing enter directly makes no change."
        } else if tokenRefExisted {
            var text = "Tap switch to turn on/off."
            if enabled {
                text += "\nReady."
            }
            informationLabel.text = text
        } else {
            informationLabel.text = "Set secret before turning on."
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
        OTPManager.sharedManager.setSecret(secretString)
        resetViewAnimated(true)
        informationLabel.text = "Secret changed."
        return true
    }

}

