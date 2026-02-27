//
//  LabelValueChip.swift
//  Planner
//
//  Created by Alex Green on 2/26/26.
//

import SwiftUI

struct LabelValueView: View {
    let label: String
    let value: String?
    let iconConfig: IconConfig

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconConfig.name)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(
                    iconConfig.primaryColor ?? .secondary,
                    iconConfig.secondaryColor ?? .secondary
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
