//
//  LabelValueChip.swift
//  Planner
//
//  Created by Alex Green on 2/26/26.
//

import SwiftUI

struct LabelValueChipView: View {
    let label: String
    let value: String?
    let iconConfig: IconConfig

    var body: some View {
        HStack {
            Image(systemName: iconConfig.name)
                .imageScale(.medium)
                .foregroundStyle(
                    iconConfig.primaryColor,
                    iconConfig.secondaryColor
                )

            VStack(alignment: .leading) {
                Text(label)
                    .font(.system(size: 14, weight: .medium))

                if let value {
                    Text(value)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(
                            Color.secondary
                        )
                }
            }
        }
        .glassChip(color: nil, onTap: nil, height: 40)
        .animateAsynchronousAction(from: value)
    }
}
