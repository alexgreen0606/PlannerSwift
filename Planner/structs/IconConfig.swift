//
//  IconConfig.swift
//  Planner
//
//  Created by Alex Green on 2/10/26.
//

import SwiftUI

// Clean

struct IconConfig: Identifiable {
    let name: String
    let primaryColor: Color
    let secondaryColor: Color

    init(
        name: String,
        primaryColor: Color = .secondary,
        secondaryColor: Color = .secondary
    ) {
        self.name = name
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
    }

    var id: String {
        "\(name)-\(primaryColor.description)"
    }
}
