//
//  settingsModalViewController.swift
//  simplepin
//
//  Created by Mathias Lindholm on 14.3.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics

class SettingsModalViewController: UITableViewController {
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    let defaults = UserDefaults(suiteName: "group.ml.simplepin")!
    let appstoreUrl = URL(string: "itms://itunes.apple.com/us/app/simplepin/id1107506693?ls=1&mt=8")!
    let emailUrl = URL(string: "mailto:mathias.lindholm@gmail.com?subject=Simplepin%20Feedback")!
    let device = UIDevice.current.userInterfaceIdiom
    var bookmarksArray: [BookmarkItem]?

    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var userDetailLabel: UILabel!
    @IBOutlet var logoutButton: UIButton!
    @IBOutlet var markAsReadSwitch: UISwitch!
    @IBOutlet var privateByDefaultSwitch: UISwitch!
    @IBOutlet var toreadByDefaultSwitch: UISwitch!
    @IBOutlet var openInSafariSwitch: UISwitch!
    @IBOutlet var versionLabel: UILabel!
    @IBOutlet var sendFeedbackCell: UITableViewCell!
    @IBOutlet var rateAppCell: UITableViewCell!
    @IBOutlet var boldTitleSwitch: UISwitch!
    @IBOutlet var relativeDateSwitch: UISwitch!
    @IBOutlet var addClipboardSwitch: UISwitch!
    @IBOutlet var headerCell: UITableViewCell!

    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        usernameLabel.text = defaults.string(forKey: "userName")

        if let bookmarks = bookmarksArray {
            let total = bookmarks.count
            let unread = bookmarks.filter{ $0.toread }.count
            let personal = bookmarks.filter{ $0.personal }.count

            userDetailLabel.text =
                "\(total) bookmark\(total == 1 ? "" : "s") \n"
                + "\(unread) unread \n"
                + "\(personal) private"
        }

        markAsReadSwitch.isOn = defaults.bool(forKey: "markAsRead")
        privateByDefaultSwitch.isOn = defaults.bool(forKey: "privateByDefault")
        toreadByDefaultSwitch.isOn = defaults.bool(forKey: "toreadByDefault")
        openInSafariSwitch.isOn = defaults.bool(forKey: "openInSafari")
        boldTitleSwitch.isOn = defaults.bool(forKey: "boldTitleFont")
        relativeDateSwitch.isOn = defaults.bool(forKey: "relativeDate")
        addClipboardSwitch.isOn = defaults.bool(forKey: "addClipboard")

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.text = version
        }

        logoutButton.tintColor = Colors.Red

        Answers.logContentView(withName: "Settings view", contentType: "View", contentId: "settings-1", customAttributes: [:])
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath as IndexPath) else { return }

        switch cell {
        case sendFeedbackCell:
            if UIApplication.shared.canOpenURL(emailUrl as URL) {
                UIApplication.shared.open(emailUrl as URL, options: [:], completionHandler: nil)
                self.tableView.deselectRow(at: indexPath as IndexPath, animated: true)
            } else {
                alertError(title: "There Was an Error Opening Mail", message: nil)
            }
        case rateAppCell:
            if UIApplication.shared.canOpenURL(appstoreUrl as URL) {
                UIApplication.shared.open(appstoreUrl as URL, options: [:], completionHandler: nil)
                self.tableView.deselectRow(at: indexPath as IndexPath, animated: true)
            } else {
                alertError(title: "There Was an Error Opening App Store", message: nil)
            }
        default: break
        }
    }

    //MARK: - Actions

    @IBAction func logoutButtonTapped(_ sender: Any) {
        let alertController = UIAlertController(
            title: device == .pad ? "Do You Want to Log out?" : nil,
            message: nil,
            preferredStyle: device == .pad ? .alert : .actionSheet)

        let actionLogout = UIAlertAction(title: "Log out", style: UIAlertAction.Style.destructive, handler: { action in
            self.dismiss(animated: true, completion: nil)
            self.appDelegate?.logOut()
        })
        let actionCancel = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)

        alertController.addAction(actionLogout)
        alertController.addAction(actionCancel)

        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = logoutButton
            popoverController.sourceRect = logoutButton.bounds
        }

        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func tapOnPrivateByDefault(_ sender: Any) {
        if privateByDefaultSwitch.isOn == true {
            Answers.logCustomEvent(withName: "Switch Pressed", customAttributes: ["Switch": "privateByDefault"])
        }
        defaults.set(privateByDefaultSwitch.isOn, forKey: "privateByDefault")
    }
    
    @IBAction func markAsReadTapped(_ sender: Any) {
        if markAsReadSwitch.isOn == true {
            Answers.logCustomEvent(withName: "Switch Pressed", customAttributes: ["Switch": "markAsRead"])
        }
        defaults.set(markAsReadSwitch.isOn, forKey: "markAsRead")
    }
    
    @IBAction func toReadByDefaultTapped(_ sender: Any) {
        if toreadByDefaultSwitch.isOn == true {
            Answers.logCustomEvent(withName: "Switch Pressed", customAttributes: ["Switch": "toreadByDefault"])
        }
        defaults.set(toreadByDefaultSwitch.isOn, forKey: "toreadByDefault")
    }
    
    @IBAction func openInSafariSwitchTapped(_ sender: Any) {
        if openInSafariSwitch.isOn == true {
            Answers.logCustomEvent(withName: "Switch Pressed", customAttributes: ["Switch": "openInSafari"])
        }
        defaults.set(openInSafariSwitch.isOn, forKey: "openInSafari")
    }

    @IBAction func boldTitleSwitchTapped(_ sender: Any) {
        if boldTitleSwitch.isOn == true {
            Answers.logCustomEvent(withName: "Switch Pressed", customAttributes: ["Switch": "boldTitleFont"])
        }
        defaults.set(boldTitleSwitch.isOn, forKey: "boldTitleFont")
    }

    @IBAction func relativeDateSwitchTapped(_ sender: Any) {
        if relativeDateSwitch.isOn == true {
            Answers.logCustomEvent(withName: "Switch Pressed", customAttributes: ["Switch": "relativeDate"])
        }
        defaults.set(relativeDateSwitch.isOn, forKey: "relativeDate")
    }
    
    @IBAction func addClipboardSwitchTapped(_ sender: Any) {
        if addClipboardSwitch.isOn == true {
            Answers.logCustomEvent(withName: "Switch Pressed", customAttributes: ["Switch": "addClipboard"])
        }
        defaults.set(addClipboardSwitch.isOn, forKey: "addClipboard")
    }
    
    @IBAction func dismissSettings(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
