//
//  CustomIconConfig.swift
//  Planner
//
//  Created by Alex Green on 2/10/26.
//

import SwiftUI

struct IconConfig {
    let name: String
    let primaryColor: Color
    let secondaryColor: Color
    
    init(name: String, primaryColor: Color = .secondary, secondaryColor: Color = .secondary) {
        self.name = name
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
    }
}
