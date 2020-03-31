//
//  Global.swift
//  Simplepin
//
//  Created by Mathias Lindholm on 13.07.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import Foundation

class BookmarkItem {
    let url: URL
    let title: String
    let description: String
    let date: Date
    let tags: [String]
    var personal: Bool
    var toread: Bool

    init?(json: [String: AnyObject]) {
        let dateString = json["time"] as? String
        let linkString = json["href"] as? String
        let tagsString = json["tags"] as? String
        let personalString = json["shared"] as? String
        let toreadString = json["toread"] as? String

        guard let url = URL(string: linkString!),
            let title = json["description"] as? String,
            let description = json["extended"] as? String,
            let date = dateString?.stringToDate,
            let tags = tagsString?.components(separatedBy: " ").filter({ !$0.isEmpty }),
            let personal = personalString?.stringToBool,
            let toread = toreadString?.stringToBool else {
                return nil
        }
        self.url = url
        self.title = title
        self.description = description
        self.date = date
        self.tags = tags
        self.personal = !personal
        self.toread = toread
    }
}


class TagItem {
    var tag: String
    var count: Int

    init?(key: String, value: String) {

        guard let count = Int(value) else {
            print("error in global")
            return nil
        }

        self.tag = key
        self.count = count
    }
}
