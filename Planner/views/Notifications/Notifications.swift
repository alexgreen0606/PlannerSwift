//
//  Notifications.swift
//  Planner
//
//  Created by Alex Green on 3/19/26.
//

import SwiftUI

struct NotificationsView: View {

    @EnvironmentObject private var notificationManager: NotificationManager

    var body: some View {
        VStack {
            Spacer()
            ZStack {
                ForEach(notificationManager.notifications, id: \.id) {
                    config in
                    NotificationChipView(config: config)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .animation(
            .linear,
            value: notificationManager.notifications
        )
    }
}
