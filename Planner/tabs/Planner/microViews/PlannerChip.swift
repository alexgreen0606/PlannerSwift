//
//  PlannerChipView.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import SwiftUI

struct PlannerChipView: View {
    let title: String
    let iconName: String?
    let color: Color
    let disableInteraction: Bool

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 4) {
                if iconName != nil {
                    Image(systemName: iconName!)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(height: UIConstants.chipHeight)
            .glassEffect(
                .regular.tint(color.opacity(0.05)).interactive(!disableInteraction),
                in: .rect(cornerRadius: UIConstants.chipHeight / 2)
            )
        }
    }
}
