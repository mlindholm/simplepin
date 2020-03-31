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

class LoginViewController: UIViewController {
    let defaults = UserDefaults(suiteName: "group.ml.simplepin")!
    let notifications = NotificationCenter.default
    var fetchApiTokenTask: URLSessionTask?
    var tokenLogin = false

    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var spinner: UIActivityIndicatorView!
    @IBOutlet var stackBottomConstraint: NSLayoutConstraint!
    @IBOutlet var forgotPasswordButton: UIButton!
    @IBOutlet var loginMethodSegment: UISegmentedControl!
    @IBOutlet var onepasswordButton: UIButton!

    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        usernameField.delegate = self
        passwordField.delegate = self

        onepasswordButton.isHidden = (false == OnePasswordExtension.shared().isAppExtensionAvailable())
        onepasswordButton.imageView?.contentMode = .scaleAspectFit

        notifications.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notifications.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        notifications.addObserver(forName: NSNotification.Name(rawValue: "handleRequestError"), object: nil, queue: nil, using: handleRequestError)
    }

    // MARK: - Login

    func loginFailed(title: String) {
        self.spinner.alpha = CGFloat(0.0)
        self.spinner.stopAnimating()
        self.loginButton.isEnabled = true
        self.alertErrorWithReachability(title: title, message: nil)
    }

    // MARK: - Actions

    @IBAction func loginButtonPressed(_ sender: Any) {
        actionLogin()
    }
    
    func actionLogin() {
        loginButton.isEnabled = false

        guard let password = passwordField.text,
            let username = usernameField.text else {
                return
        }

        if password.isEmpty || username.isEmpty {
            loginButton.isEnabled = true

            if tokenLogin == true {
                if password.isEmpty {
                    self.alertError(title: "Please Enter Your API Token", message: nil)
                    return
                }
            } else {
                self.alertError(title: "Please Enter Your Username and Password", message: nil)
                return
            }
        }

        spinner.alpha = CGFloat(1.0)
        spinner.startAnimating()

        switch tokenLogin {
        case true:
            fetchApiTokenTask = Network.loginWithApiToken(token: password) { result in
                if result != nil {
                    let token = password.removeExcessiveSpaces
                    let username = token.components(separatedBy: ":").first
                    self.defaults.set(token, forKey: "userToken")
                    self.defaults.set(username, forKey: "userName")
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "loginSuccessful"), object: nil)
                    self.dismiss(animated: true, completion: nil)
                    Answers.logLogin(withMethod: "API Token", success: true, customAttributes: [:])
                } else {
                    self.loginFailed(title: "Incorrect API Token")
                    return
                }
            }
        default:
            fetchApiTokenTask = Network.loginWithUsernamePassword(username: username, password) { result in
                if let token = result {
                    let token = username + ":" + token
                    self.defaults.set(token, forKey: "userToken")
                    self.defaults.set(username, forKey: "userName")
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "loginSuccessful"), object: nil)
                    self.dismiss(animated: true, completion: nil)
                    Answers.logLogin(withMethod: "Username and Password", success: true, customAttributes: [:])
                } else {
                    self.loginFailed(title: "Incorrect Username or Password")
                    return
                }
            }
        }
    }
    
    @IBAction func forgotPasswordButtonTapped(_ sender: Any) {
        let urlString = self.tokenLogin == true ? "https://m.pinboard.in/settings/password" : "https://m.pinboard.in/password_reset/"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func loginMethodSegmentTaped(_ sender: Any) {
        passwordField.text = ""

        switch loginMethodSegment.selectedSegmentIndex {
        case 0:
            tokenLogin = false
            forgotPasswordButton.setTitle("Forgot Password?", for: .normal)
            usernameField.isHidden = false
            passwordField.placeholder = "Password"
        case 1:
            tokenLogin = true
            forgotPasswordButton.setTitle("Show API Token", for: .normal)
            usernameField.isHidden = true
            passwordField.placeholder = "Username:Token"
        default:
            break
        }
    }
    
    @IBAction func findLoginFrom1Password(_ sender: Any) {
        OnePasswordExtension.shared().findLogin(forURLString: "https://pinboard.in", for: self, sender: sender, completion: { (loginDictionary, error) -> Void in
                    if loginDictionary == nil {
        //                if error!.code != Int(AppExtensionErrorCodeCancelledByUser) {
        //                    print("Error invoking 1Password App Extension for find login: \(error)")
        //                }
                        return
                    }

                    self.usernameField.text = loginDictionary?[AppExtensionUsernameKey] as? String
                    self.passwordField.text = loginDictionary?[AppExtensionPasswordKey] as? String

                    self.actionLogin()
                })
    }

    //MARK: - Events
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        usernameField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }

    @objc func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        let keyboardEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let convertedKeyboardEndFrame = view.convert(keyboardEndFrame, from: view.window)

        self.stackBottomConstraint.constant = view.bounds.maxY - convertedKeyboardEndFrame.minY + 8
        UIView.animate(withDuration: 0.1) {
            self.view.layoutSubviews()
        }
    }

    @objc func keyboardWillHide(notification: Notification) {
        stackBottomConstraint.constant = 16
        UIView.animate(withDuration: 0.1) {
            self.view.layoutSubviews()
        }
    }

    func handleRequestError(notification: Notification) {
        if let info = notification.userInfo as? Dictionary<String, String> {
            guard let title = info["title"],
                let message = info["message"] else {
                    return
            }
            alertError(title: title, message: message)
        }
    }

    deinit {
        notifications.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        notifications.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        notifications.removeObserver(self, name: NSNotification.Name(rawValue: "handleRequestError"), object: nil)
    }
}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            actionLogin()
        }
        return true
    }
}
