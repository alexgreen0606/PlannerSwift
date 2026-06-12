//
//  CGColor+ Hex.swift
//  Planner
//
//  Created by Alex Green on 6/11/26.
//

import UIKit

extension CGColor {
    var hexString: String {
        guard
            let converted = converted(
                to: CGColorSpace(name: CGColorSpace.sRGB)!,
                intent: .defaultIntent,
                options: nil
            ),
            let components = converted.components,
            components.count >= 3
        else {
            return "#FFFFFF"
        }

        let red = Int(round(components[0] * 255))
        let green = Int(round(components[1] * 255))
        let blue = Int(round(components[2] * 255))

        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
