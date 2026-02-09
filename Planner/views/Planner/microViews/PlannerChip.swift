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
    let color: Color?
    let onTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 4) {
            if let iconName {
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundColor(color ?? Color(uiColor: .label))
            }

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color ?? Color(uiColor: .label))
        }
        .glassChip(color: color, onTap: onTap)
    }
}
