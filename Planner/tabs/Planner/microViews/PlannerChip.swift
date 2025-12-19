//
//  PlannerChipView.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import SwiftUI

struct PlannerChipView: View {
    let title: String
    let iconName: String
    let color: Color

    private let chipHeight: CGFloat = 28

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 4) {
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(height: chipHeight)
            .glassEffect(.regular.tint(color.opacity(0.05)), in: .rect(cornerRadius: chipHeight / 2))
        }
    }
}

