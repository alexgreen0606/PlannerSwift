//
//  Color.swift
//  Planner
//
//  Created by Alex Green on 12/19/25.
//

import SwiftUI

// Clean

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
        let light = UIColor.secondarySystemBackground
        let dark = UIColor.black

        return Color(
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? dark : light
            }
        )
    }
    
    static var sheetBackground: Color {
        let light = UIColor.secondarySystemBackground
        let dark = UIColor.systemBackground

        return Color(
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? dark : light
            }
        )
    }

    static var cardBackground: Color {
        let light = UIColor.systemBackground
        let dark = UIColor.secondarySystemBackground

        return Color(
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? dark : light
            }
        )
    }

    static var inverseLabel: Color {
        let light = UIColor.white
        let dark = UIColor.black

        return Color(
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? dark : light
            }
        )
    }
    
}
