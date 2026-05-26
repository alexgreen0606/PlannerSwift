//
//  Color+.swift
//  Planner
//
//  Created by Alex Green on 12/19/25.
//

import SwiftUI

extension Color {
    static var label: Color {
        Color(uiColor: .label)
    }

    static var secondary: Color {
        Color(uiColor: .secondaryLabel)
    }

    static var tertiary: Color {
        Color(uiColor: .tertiaryLabel)
    }

    static var appBackground: Color {
        themedColor(
            light: UIColor.secondarySystemBackground,
            dark: UIColor.black
        )
    }

    static var sheetBackground: Color {
        themedColor(
            light: UIColor.secondarySystemBackground,
            dark: UIColor.systemBackground
        )
    }

    static var cardBackground: Color {
        themedColor(
            light: UIColor.systemBackground,
            dark: UIColor.secondarySystemBackground
        )
    }

    static var inverseLabel: Color {
        themedColor(
            light: UIColor.white,
            dark: UIColor.black
        )
    }

    private static func themedColor(light: UIColor, dark: UIColor) -> Color {
        Color(
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? dark : light
            }
        )
    }
}
