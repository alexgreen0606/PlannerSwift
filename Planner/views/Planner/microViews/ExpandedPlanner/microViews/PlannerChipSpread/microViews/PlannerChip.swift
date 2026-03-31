//
//  PlannerChip.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import Contacts
import SwiftUI

// Clean

struct PlannerChipView: View {
    let title: String
    let iconConfig: IconConfig?
    let color: Color?
    let contact: CNContact?
    let onTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 6) {
            if let data = contact?.thumbnailImageData,
                let image = UIImage(data: data)
            {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
                    .padding(.leading, 4 - (PlannerLayout.CHIP_HEIGHT / 3))
            } else if let iconConfig {
                Image(systemName: iconConfig.name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundStyle(
                        iconConfig.primaryColor,
                        iconConfig.secondaryColor
                    )
            }

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color ?? Color.label)
        }
        .glassChip(color: color, onTap: onTap)
    }
}
