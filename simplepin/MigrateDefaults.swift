//
//  MigrateDefaults.swift
//  simplepin
//
//  Created by Mathias Lindholm on 8.7.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import Foundation

func migrateUserDefaultsToAppGroups() {
    let userDefaults = UserDefaults.standard
    let groupDefaults = UserDefaults(suiteName: "group.ml.simplepin")
    let didMigrateToAppGroups = "DidMigrateToAppGroups"

    if let groupDefaults = groupDefaults {
        if !groupDefaults.bool(forKey: didMigrateToAppGroups) {
            for key in userDefaults.dictionaryRepresentation().keys {
                groupDefaults.set(userDefaults.dictionaryRepresentation()[key], forKey: key)
            }
            groupDefaults.set(true, forKey: didMigrateToAppGroups)
        }
    }
}
