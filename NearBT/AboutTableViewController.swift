//
//  AboutTableViewController.swift
//  NearBT
//
//  Created by guoc on 31/03/2016.
//  Copyright © 2016 guoc. All rights reserved.
//

import UIKit

class AboutTableViewController: UITableViewController {

    @IBOutlet weak var versionLabel: UILabel! {
        didSet {
            guard let info = NSBundle.mainBundle().infoDictionary,
                let shortVersion = info["CFBundleShortVersionString"] as? String,
                let buildVersion = info["CFBundleVersion"] as? String else {
                    assertionFailure("Fail to get version number.")
                    versionLabel.text = "Unknown"
                    return
            }
            let version = shortVersion + " (" + buildVersion + ")"
            versionLabel.text = version
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

}
