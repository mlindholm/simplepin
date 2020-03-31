//
//  StringExtension.swift
//  simplepin
//
//  Created by Mathias Lindholm on 4.4.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import Foundation

extension String {
    var stringToDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.date(from: self)
    }

    var sentencecaseString: String {
        if isEmpty { return "" }
        let lowercaseString = self.lowercased()
        return lowercaseString.replacingCharacters(in: lowercaseString.startIndex...lowercaseString.startIndex, with: String(lowercaseString[lowercaseString.startIndex]).uppercased())
    }

    var removeExcessiveSpaces: String {
        let components = self.components(separatedBy: CharacterSet.whitespaces)
        let filtered = components.filter({!$0.isEmpty})
        return filtered.joined(separator: " ")
    }

    var stringToBool: Bool {
        return NSString(string: self).boolValue
    }
}
