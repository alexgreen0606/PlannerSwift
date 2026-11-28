//
//  AdornedValue.swift
//  Planner
//
//  Created by Alex Green on 4/1/26.
//

import SwiftUI

struct AdornedValue: View {
    private let text: String?
    private let iconConfig: IconConfig?
    private let additionalIconConfigs: [IconConfig]
    private let endAdorned: Bool
    private let lineLimit: Int?
    private let color: Color?
    private let scale: Double
    private let weight: Font.Weight
    private let design: Font.Design

    init(
        _ text: String? = nil,
        iconConfig: IconConfig? = nil,
        additionalIconConfigs: [IconConfig] = [],
        endAdorned: Bool = false,
        lineLimit: Int? = nil,
        color: Color? = nil,
        scale: Double = 1,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) {
        self.text = text
        self.iconConfig = iconConfig
        self.additionalIconConfigs = additionalIconConfigs
        self.endAdorned = endAdorned
        self.lineLimit = lineLimit
        self.color = color
        self.scale = scale
        self.weight = weight
        self.design = design
    }

    private var iconSize: CGFloat {
        Layout.TEXT * scale
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: Layout.DEFAULT_ADORNMENT_SPACING * scale) {
            if !endAdorned {
                if let iconConfig {
                    Image(systemName: iconConfig.name)
                        .foregroundStyle(
                            iconConfig.primaryColor,
                            iconConfig.secondaryColor
                        )
                }

                ForEach(additionalIconConfigs, id: \.id) { iconConfig in
                    Image(systemName: iconConfig.name)
                        .foregroundStyle(
                            iconConfig.primaryColor,
                            iconConfig.secondaryColor
                        )
                }
            }

            if let text {
                Value(
                    text,
                    color: color,
                    scale: scale,
                    weight: weight,
                    design: design
                )
                    .lineLimit(lineLimit)
            }

            if endAdorned {
                if let iconConfig {
                    Image(systemName: iconConfig.name)
                        .foregroundStyle(
                            iconConfig.primaryColor,
                            iconConfig.secondaryColor
                        )
                }

                ForEach(additionalIconConfigs, id: \.id) { iconConfig in
                    Image(systemName: iconConfig.name)
                        .foregroundStyle(
                            iconConfig.primaryColor,
                            iconConfig.secondaryColor
                        )
                }
            }
        }
        .font(.system(size: iconSize, weight: weight, design: design))
    }
}
