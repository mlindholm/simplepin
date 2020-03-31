//
//  Helpers.swift
//  Simplepin
//
//  Created by Florian Mari on 16/03/2020.
//  Copyright © 2020 Mathias Lindholm. All rights reserved.
//

import Foundation

class Helpers {
    static func open(scheme: String) {
      if let url = URL(string: scheme) {
        if #available(iOS 10, *) {
          UIApplication.shared.open(url, options: [:],
            completionHandler: {
              (success) in
               print("Open \(scheme): \(success)")
           })
        } else {
          let success = UIApplication.shared.openURL(url)
          print("Open \(scheme): \(success)")
        }
      }
    }
}
