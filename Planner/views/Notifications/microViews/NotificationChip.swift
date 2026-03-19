//
//  NotificationChip.swift
//  Planner
//
//  Created by Alex Green on 3/18/26.
//

import SwiftUI

struct NotificationChipView: View {
    let config: NotificationConfig

    @State private var showImage = false

    var body: some View {
        HStack {
            Image(systemName: config.iconConfig.name)
                .symbolEffect(.drawOn, isActive: !showImage)
                .imageScale(.medium)
                .foregroundStyle(
                    config.iconConfig.primaryColor,
                    config.iconConfig.secondaryColor
                )

            VStack(alignment: .leading) {
                Text(config.title)
                    .font(.system(size: 14, weight: .medium))

                if let subtitle = config.subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(
                            Color.secondary
                        )
                }
            }
        }
        .glassChip(
            color: nil,
            onTap: config.onClick,
            height: config.subtitle != nil ? 50 : 40
        )
        .transition(.move(edge: .leading).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(800))
            {
                withAnimation {
                    showImage = true
                }
            }
        }
    }
}
