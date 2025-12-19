//
//  Color.swift
//  Planner
//
//  Created by Alex Green on 12/19/25.
//

import SwiftUI

extension Color {
    static var appBackground: Color {
        let light = UIColor.secondarySystemBackground
        let dark = UIColor.black

        return Color(
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? dark : light
            }
        )
    }
}
