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

    init(_ title: String, color: Color? = nil, scale: Double = 1) {
        self.title = title
        self.scale = scale

        customColor = color
    }

    private let customColor: Color?

    private var fontSize: CGFloat {
        Layout.TEXT * scale
    }

    // MARK: - Body

    var body: some View {
        Text(title)
            .font(.system(size: fontSize, weight: .regular))
            .foregroundColor(customColor ?? Color.label)
    }
}
