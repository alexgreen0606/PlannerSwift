//
//  IconConfig.swift
//  Planner
//
//  Created by Alex Green on 2/10/26.
//

import SwiftUI

struct IconConfig: Identifiable {
    let name: String
    let primaryColor: Color
    let secondaryColor: Color
    let scale: Image.Scale

    init(
        name: String,
        primaryColor: Color = .secondary,
        secondaryColor: Color = .secondary,
        scale: Image.Scale = .medium
    ) {
        self.name = name
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.scale = scale
    }

    var id: String {
        "\(name)-\(primaryColor.description)-\(secondaryColor.description)"
    }
}
