//
//  LoginViewController.swift
//  simplepin
//
//  Created by Mathias Lindholm on 30.03.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import SafariServices

class LoginModalViewController: UIViewController {
    let defaults = NSUserDefaults(suiteName: "group.ml.simplepin")!
    let notifications = NSNotificationCenter.defaultCenter()
    var fetchApiTokenTask: NSURLSessionTask?
    var tokenLogin = false

    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var spinner: UIActivityIndicatorView!
    @IBOutlet var stackBottomConstraint: NSLayoutConstraint!
    @IBOutlet var forgotPasswordButton: UIButton!
    @IBOutlet var loginMethodSegment: UISegmentedControl!
    @IBOutlet var onepasswordButton: UIButton!

    @IBAction func loginButtonPressed(sender: AnyObject?) {
        loginButton.enabled = false

        guard let password = passwordField.text,
            let username = usernameField.text else {
                return
        }

        if password.isEmpty || username.isEmpty {
            loginButton.enabled = true

            if tokenLogin == true {
                if password.isEmpty {
                    self.alertError("Please Enter Your API Token", message: nil)
                    return
                }
            } else {
                self.alertError("Please Enter Your Username and Password", message: nil)
                return
            }
        }

        spinner.alpha = CGFloat(1.0)
        spinner.startAnimating()
        fetchApiTokenTask = Network.fetchApiToken(username, password, loginWithToken: tokenLogin) { userToken in
            if let token = userToken {
                if self.tokenLogin == true {
                    let token = password.removeExcessiveSpaces
                    let username = token.componentsSeparatedByString(":")
                    self.defaults.setObject(token, forKey: "userToken")
                    self.defaults.setObject(username[0], forKey: "userName")
                    Answers.logLoginWithMethod("API Token", success: true, customAttributes: [:])
                } else {
                    self.defaults.setObject(username+":"+token, forKey: "userToken")
                    self.defaults.setObject(username, forKey: "userName")
                    Answers.logLoginWithMethod("Username and Password", success: true, customAttributes: [:])
                }
                NSNotificationCenter.defaultCenter().postNotificationName("loginSuccessful", object: nil)
                self.dismissViewControllerAnimated(true, completion: nil)
            } else {
                self.spinner.alpha = CGFloat(0.0)
                self.spinner.stopAnimating()
                self.loginButton.enabled = true
                let title = "Incorrect \(self.tokenLogin == true ? "API Token" : "Username or Password")"
                self.alertErrorWithReachability(title, message: nil)
                return
            }
        }
    }

    @IBAction func forgotPasswordButtonPressed(sender: AnyObject) {
        let urlString = self.tokenLogin == true ? "https://m.pinboard.in/settings/password" : "https://m.pinboard.in/password_reset/"
        let url = NSURL(string: urlString)
        UIApplication.sharedApplication().openURL(url!)
    }

    @IBAction func loginMethodSegmentPressed(sender: AnyObject) {
        passwordField.text = ""

        switch loginMethodSegment.selectedSegmentIndex {
        case 0:
            tokenLogin = false
            forgotPasswordButton.setTitle("Forgot Password?", forState: .Normal)
            usernameField.hidden = false
            passwordField.placeholder = "Password"
        case 1:
            tokenLogin = true
            forgotPasswordButton.setTitle("Show API Token", forState: .Normal)
            usernameField.hidden = true
            passwordField.placeholder = "Username:Token"
        default:
            break
        }
    }

    @IBAction func findLoginFrom1Password(sender: AnyObject) -> Void {
        OnePasswordExtension.sharedExtension().findLoginForURLString("https://pinboard.in", forViewController: self, sender: sender, completion: { (loginDictionary, error) -> Void in
            if loginDictionary == nil {
                if error!.code != Int(AppExtensionErrorCodeCancelledByUser) {
                    print("Error invoking 1Password App Extension for find login: \(error)")
                }
                return
            }

            self.usernameField.text = loginDictionary?[AppExtensionUsernameKey] as? String
            self.passwordField.text = loginDictionary?[AppExtensionPasswordKey] as? String

            self.loginButtonPressed(nil)
        })

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        usernameField.delegate = self
        passwordField.delegate = self

        onepasswordButton.hidden = (false == OnePasswordExtension.sharedExtension().isAppExtensionAvailable())
        onepasswordButton.imageView?.contentMode = .ScaleAspectFit

        notifications.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        notifications.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        notifications.addObserverForName("handleRequestError", object: nil, queue: nil, usingBlock: handleRequestError)
    }

    override func viewWillDisappear(animated: Bool) {
        notifications.removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        notifications.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        usernameField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }

    func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let convertedKeyboardEndFrame = view.convertRect(keyboardEndFrame, fromView: view.window)

        self.stackBottomConstraint.constant = CGRectGetMaxY(view.bounds) - CGRectGetMinY(convertedKeyboardEndFrame) + 8
        UIView.animateWithDuration(0.1) {
            self.view.layoutSubviews()
        }
    }

    func keyboardWillHide(notification: NSNotification) {
        stackBottomConstraint.constant = 16
        UIView.animateWithDuration(0.1) {
            self.view.layoutSubviews()
        }
    }

    func handleRequestError(notification: NSNotification) {
        if let info = notification.userInfo as? Dictionary<String, String> {
            guard let title = info["title"],
                let message = info["message"] else {
                    return
            }
            alertError(title, message: message)
        }
    }
}

// MARK: - UITextFieldDelegate
extension LoginModalViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            loginButtonPressed(nil)
        }
        return true
    }
}