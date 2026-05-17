//
//  syncAppIconWithSettings.swift
//  Planner
//
//  Created by Alex Green on 4/4/26.
//

import SwiftUI

// Clean

func syncAppIconWithSettings(
    accentColor: AccentColor,
    systemColorScheme: ColorScheme
) {
    guard UIApplication.shared.supportsAlternateIcons else {
        return
    }

    var newIcon: String? =
        "\(accentColor.rawValue)\(systemColorScheme == .dark ? "dark" : "light")"

    if newIcon == "bluedark" {
        newIcon = nil
    }

    if UIApplication.shared.alternateIconName == newIcon {
        return
    }

    UIApplication.shared.setAlternateIconName(newIcon) { error in
        if let error = error {
            print(
                "Error setting icon \(newIcon ?? "bluedark"): \(error.localizedDescription)"
            )
        }
    }
}
