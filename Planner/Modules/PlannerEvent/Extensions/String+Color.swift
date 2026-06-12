//
//  String+Color.swift
//  Planner
//
//  Created by Alex Green on 6/11/26.
//

import SwiftUI

extension String {
    var color: Color? {
        let hex = trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

        guard hex.count == 6 || hex.count == 8,
              let int = UInt64(hex, radix: 16)
        else {
            return nil
        }

        let red, green, blue, alpha: UInt64

        if hex.count == 8 {
            red = (int >> 24) & 0xFF
            green = (int >> 16) & 0xFF
            blue = (int >> 8) & 0xFF
            alpha = int & 0xFF
        } else {
            red = (int >> 16) & 0xFF
            green = (int >> 8) & 0xFF
            blue = int & 0xFF
            alpha = 0xFF
        }

        return Color(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}
