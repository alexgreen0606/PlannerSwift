//
//  syncAppIconWithSettings.swift
//  Planner
//
//  Created by Alex Green on 4/4/26.
//

import SwiftUI

func syncAppIconWithSettings(
    accentColor: AccentColor,
    systemColorScheme: ColorScheme
) {
    guard UIApplication.shared.supportsAlternateIcons else {
        return
    }

    let alernateIconName: String? =
        accentColor == .blue && systemColorScheme == .dark
        ? nil // Default icon is bluedark.
        : "\(accentColor)\(systemColorScheme)"

    if UIApplication.shared.alternateIconName == alernateIconName {
        return
    }

    UIApplication.shared.setAlternateIconName(alernateIconName) { error in
        if let error {
            print(
                "ERROR syncAppIconWithSettings: \(error)"
            )
        }
    }
}
