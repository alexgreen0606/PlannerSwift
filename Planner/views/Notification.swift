//
//  Notification.swift
//  Planner
//
//  Created by Alex Green on 3/18/26.
//

import SwiftUI

struct NotificationView: View {
    let config: NotificationConfig

    var body: some View {
        HStack {
            Image(systemName: config.iconConfig.name)
                .imageScale(.medium)
                .foregroundStyle(
                    config.iconConfig.primaryColor,
                    config.iconConfig.secondaryColor
                )
                .transition(.symbolEffect(.drawOn))

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
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
