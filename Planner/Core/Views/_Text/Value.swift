//
//  Value.swift
//  Planner
//
//  Created by Alex Green on 4/1/26.
//

import SwiftUI

struct Value: View {
    private let title: String
    private let scale: Double
    private let weight: Font.Weight
    private let design: Font.Design

    init(
        _ title: String,
        color: Color? = nil,
        scale: Double = 1,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) {
        self.title = title
        self.scale = scale
        self.weight = weight
        self.design = design

        customColor = color
    }

    private let customColor: Color?

    private var fontSize: CGFloat {
        Layout.TEXT * scale
    }

    // MARK: - Body

    var body: some View {
        Text(title)
            .font(.system(size: fontSize, weight: weight, design: design))
            .foregroundColor(customColor ?? Color.label)
    }
}
