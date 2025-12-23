//
//  DashedDivider.swift
//  Planner
//
//  Created by Alex Green on 12/22/25.
//

import SwiftUI

struct DashedDivider: View {
    @Environment(\.displayScale) private var displayScale
    
    var color: Color = Color(uiColor: .tertiaryLabel)
    var dash: [CGFloat] = [2, 6]

    var body: some View {
            let lineWidth = 1 / displayScale

            Rectangle()
                .fill(Color.clear)
                .frame(height: lineWidth)
                .overlay(
                    Rectangle()
                        .stroke(
                            color,
                            style: StrokeStyle(
                                lineWidth: lineWidth,
                                dash: dash
                            )
                        )
                )
        }
}
