//
//  BoolExtension.swift
//  simplepin
//
//  Created by Mathias Lindholm on 11.7.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import Foundation

extension Bool {

    var boolToString: String {
        if self == true {
            return "yes"
        } else {
            return "no"
        }
    }
}
