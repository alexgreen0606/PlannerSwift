//
//  TodaystampWatcher.swift
//  Planner
//
//  Created by Alex Green on 12/5/25.
//

import Combine
import Foundation
import SwiftDate

@MainActor
class TodaystampWatcher: ObservableObject {
    
    init() {
        scheduleMidnightUpdate()
    }

    @Published private(set) var todaystamp: String =
        TodaystampWatcher.makeStamp()
    
    @Published private(set) var maxCalendarDate: Date =
        TodaystampWatcher.makeMaxCalendarDate()

    private var timer: Timer?

    deinit {
        timer?.invalidate()
    }

    private static func makeStamp() -> String {
        DateInRegion(region: .local).toFormat(
            "yyyy-MM-dd",
            locale: Locale.current
        )
    }
    
    private static func makeMaxCalendarDate() -> Date {
        DateInRegion(Date(), region: .local)
            .dateByAdding(3, .year)
            .date
    }

    private func scheduleMidnightUpdate() {
        timer?.invalidate()

        let now = DateInRegion(region: .local)
        let nextMidnight = now.dateAt(.tomorrowAtStart)

        timer = Timer(
            fireAt: nextMidnight.date,
            interval: 0,
            target: self,
            selector: #selector(updateStamp),
            userInfo: nil,
            repeats: false
        )

        RunLoop.main.add(timer!, forMode: .common)
    }

    @objc private func updateStamp() {
        todaystamp = Self.makeStamp()
        maxCalendarDate = Self.makeMaxCalendarDate()

        // Reschedule for tomorrow.
        scheduleMidnightUpdate()
    }
}
