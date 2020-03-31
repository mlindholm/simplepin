//
//  OptionsTableViewController.swift
//  simplepin
//
//  Created by Mathias Lindholm on 7.7.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import UIKit

protocol OptionsTableViewDelegate: class {
    func didEnterInformation(data: Bookmark)
}

class OptionsTableViewController: UITableViewController {
    weak var delegate: OptionsTableViewDelegate? = nil
    var passedBookmark = Bookmark()
    let groupDefaults = UserDefaults(suiteName: "group.ml.simplepin")!

    var descriptionCell: UITableViewCell = UITableViewCell()
    var tagsCell: UITableViewCell = UITableViewCell()
    var shareCell: UITableViewCell = UITableViewCell()
    var toreadCell: UITableViewCell = UITableViewCell()
    var descriptionLabel: UITextField = UITextField()
    var tagsLabel: UITextField = UITextField()
    var privateSwitch: UISwitch = UISwitch()
    var toreadSwitch: UISwitch = UISwitch()

    override func loadView() {
        super.loadView()

        self.title = "Options"

        self.descriptionLabel = UITextField(frame: self.descriptionCell.contentView.bounds.insetBy(dx: 15, dy: 0))
        self.descriptionLabel.placeholder = "Description"
        self.descriptionLabel.autocorrectionType = .default
        self.descriptionLabel.autocapitalizationType = .sentences
        self.descriptionCell.addSubview(self.descriptionLabel)

        self.tagsLabel = UITextField(frame: self.tagsCell.contentView.bounds.insetBy(dx: 15, dy: 0))
        self.tagsLabel.placeholder = "Tags (separated by space)"
        self.tagsLabel.autocorrectionType = .default
        self.tagsLabel.autocapitalizationType = .none
        self.tagsCell.addSubview(self.tagsLabel)

        self.shareCell.textLabel?.text = "Private"
        self.privateSwitch.isOn = groupDefaults.bool(forKey: "privateByDefault")
        self.shareCell.accessoryView = privateSwitch
        self.shareCell.addSubview(self.privateSwitch)

        self.toreadCell.textLabel?.text = "Read Later"
        self.toreadSwitch.isOn = groupDefaults.bool(forKey: "toreadByDefault")
        self.toreadCell.accessoryView = toreadSwitch
        self.toreadCell.addSubview(self.toreadSwitch)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nil

        descriptionLabel.text = passedBookmark.description
        tagsLabel.text = passedBookmark.tags.joined(separator: " ")
        privateSwitch.isOn = passedBookmark.personal
        toreadSwitch.isOn = passedBookmark.toread
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)

        guard let description = descriptionLabel.text,
            let tags = tagsLabel.text?.components(separatedBy: " ") else { return }

        passedBookmark.description = description
        passedBookmark.tags = tags
        passedBookmark.personal = privateSwitch.isOn
        passedBookmark.toread = toreadSwitch.isOn

        delegate?.didEnterInformation(data: passedBookmark)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {switch(indexPath.row) {
        case 0: return self.descriptionCell
        case 1: return self.tagsCell
        case 2: return self.shareCell
        case 3: return self.toreadCell
        default: fatalError("Unknown row in section 0")
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = nil
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
    }
}
