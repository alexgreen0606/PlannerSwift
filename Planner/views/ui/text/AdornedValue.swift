//
//  AdornedValue.swift
//  Planner
//
//  Created by Alex Green on 4/1/26.
//

import SwiftUI

// Clean

struct AdornedValueView: View {
    private let title: String
    private let color: Color?
    private let iconConfig: IconConfig
    private let scale: Double

    init(
        _ title: String,
        color: Color? = nil,
        iconConfig: IconConfig,
        scale: Double? = nil
    ) {
        self.title = title
        self.iconConfig = iconConfig
        self.color = color
        self.scale = scale ?? 1
    }

    private var iconSize: CGFloat {
        14 * scale
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconConfig.name)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(
                    iconConfig.primaryColor,
                    iconConfig.secondaryColor
                )

            ValueView(title, color: color)
        }
    }
}
