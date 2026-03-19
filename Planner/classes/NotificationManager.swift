//
//  NotificationManager.swift
//  Planner
//
//  Created by Alex Green on 3/18/26.
//

import Combine
import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

@MainActor
class NotificationManager: ObservableObject {

    @Published private(set) var notifications: [NotificationConfig] = []

    func addNotification(_ notification: NotificationConfig) {
        withAnimation {
            notifications.append(notification)
        }

        Task {
            do {
                try await Task.sleep(for: .seconds(5))

                if let index = notifications.firstIndex(where: {
                    $0.id == notification.id
                }) {
                    notifications.remove(at: index)
                }
            } catch {}
        }
    }

}
