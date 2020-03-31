//
//  AddBookmarkTableViewController.swift
//  simplepin
//
//  Created by Mathias Lindholm on 9.4.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics

class AddBookmarkTableViewController: UITableViewController, UITextViewDelegate, UITextFieldDelegate {
    let defaults = UserDefaults(suiteName: "group.ml.simplepin")!
    var addBookmarkTask: URLSessionTask?
    var passedUrl: URL?
    var bookmarkDate: Date?
    var bookmark: BookmarkItem?
    var tagsArray: [TagItem]?

    @IBOutlet var privateSwitch: UISwitch!
    @IBOutlet var toreadSwitch: UISwitch!
    @IBOutlet var urlTextField: UITextField!
    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var descriptionTextView: UITextView!
    @IBOutlet var tagsTextField: UITextField!
    @IBOutlet var addButton: UIBarButtonItem!

    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        descriptionTextView.delegate = self
        urlTextField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: UIControl.Event.editingChanged)
        titleTextField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: UIControl.Event.editingChanged)

        privateSwitch.isOn = defaults.bool(forKey: "privateByDefault")
        toreadSwitch.isOn = defaults.bool(forKey: "toreadByDefault")

        if let bookmark = bookmark {
            navigationItem.title = "Edit Bookmark"
            addButton.title = "Save"
            urlTextField.text = bookmark.url.absoluteString
            titleTextField.text = bookmark.title
            descriptionTextView.text = bookmark.description
            tagsTextField.text = bookmark.tags.joined(separator: " ")
            bookmarkDate = bookmark.date
            privateSwitch.isOn = bookmark.personal
            toreadSwitch.isOn = bookmark.toread
        } else {
            bookmarkDate = nil
        }

        if let url = passedUrl {
            urlTextField.text = url.absoluteString
        }

        checkValidBookmark()

        if !descriptionTextView.text.isEmpty {
            descriptionTextView.backgroundColor = UIColor.white
        }

        Answers.logContentView(withName: "Add/edit bookmark view", contentType: "View", contentId: "addedit-1", customAttributes: [:])
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        addBookmarkTask?.cancel()
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            guard let tags = tagsArray else { return nil }
            let popular = tags.filter{ $0.count > 1 }.map{ $0.tag }
            let title = "Top tags: " + popular.joined(separator: ", ")
            return title
        } else {
            return nil
        }
    }

    //MARK: - Actions
    @IBAction func addButtonTapped(_ sender: Any) {
        guard let urlText = urlTextField.text,
            let url = URL(string: urlText),
            let title = titleTextField.text,
            let description = descriptionTextView.text,
            let tags = tagsTextField.text?.components(separatedBy: " ") else {
                return
        }

        if Reachability.isConnectedToNetwork() == false {
            alertError(title: "Couldn't Add Bookmark", message: "Try again when you're back online.")
        } else {
            self.addBookmarkTask = Network.addBookmark(url: url, title: title, shared: privateSwitch.isOn, description: description, tags: tags, dt: bookmarkDate, toread: toreadSwitch.isOn) { resultCode in
                if resultCode == "done" {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "bookmarkAdded"), object: nil)
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.alertErrorWithReachability(title: "Something Went Wrong", message: resultCode)
                }
            }
        }
    }

    //MARK: - Functions

    func checkValidBookmark() {
        let url = urlTextField.text ?? ""
        let title = titleTextField.text ?? ""
        if !url.isEmpty && !title.isEmpty {
            addButton.isEnabled = true
        } else {
            addButton.isEnabled = false
        }
    }

    @objc private func textFieldDidChange(textField: UITextField) {
        checkValidBookmark()
    }

    func textViewDidChange(_ textView: UITextView) {
        if descriptionTextView.text.isEmpty {
            descriptionTextView.backgroundColor = nil
        } else {
            descriptionTextView.backgroundColor = .white
        }
    }
    
    @IBAction func dismissAddBookmark(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
