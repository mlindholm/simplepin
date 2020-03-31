//
//  NSDateExtension.swift
//  simplepin
//
//  Created by Mathias Lindholm on 4.4.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import Foundation

extension Date {
    var dateToString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter.string(from: self)
    }

    func timeAgo() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self, to: now)

        let componentsFormatter = DateComponentsFormatter()
        componentsFormatter.calendar?.locale = Locale(identifier: "en")

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en")
        formatter.dateFormat = "MMMM yyyy"

        func formatTimeAgo(unit: NSCalendar.Unit) -> String {
            componentsFormatter.allowedUnits = unit
            componentsFormatter.unitsStyle = .full
            guard let string = componentsFormatter.string(from: self, to: now) else { return "" }
            return string + " ago"
        }
        
        guard let componentsDay = components.day, let componentsHour = components.hour, let componentsMinute = components.minute else {
            return "No day in date"
        }

        if componentsDay > 90 {
            return formatter.string(from: self)
        }

        if componentsDay > 21 {
            return formatTimeAgo(unit: .weekOfMonth)
        }

        if componentsDay > 0 {
            return formatTimeAgo(unit: .day)
        }

        if componentsHour > 0 {
            return formatTimeAgo(unit: .hour)
        }

        if componentsMinute > 0 {
            return formatTimeAgo(unit: .minute)
        }

        return "Just now"
    }

}
