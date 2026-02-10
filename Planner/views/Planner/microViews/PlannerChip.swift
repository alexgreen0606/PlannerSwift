//
//  PlannerChipView.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import SwiftUI

struct PlannerChipView: View {
    let title: String
    let iconConfig: IconConfig?
    let color: Color?
    let onTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 4) {
            if let iconConfig {
                Image(systemName: iconConfig.name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundStyle(
                        iconConfig.primaryColor ?? color
                            ?? Color(uiColor: .label),
                        iconConfig.secondaryColor ?? Color(uiColor: .label)
                    )
            }

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color ?? Color(uiColor: .label))
        }
        .glassChip(color: color, onTap: onTap)
    }
}
