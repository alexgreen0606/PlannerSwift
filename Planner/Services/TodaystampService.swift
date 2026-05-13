//
//  TodaystampService.swift
//  Planner
//
//  Created by Alex Green on 12/5/25.
//

import Combine
import Foundation
import SwiftDate

@MainActor
class TodaystampService: ObservableObject {

    init() {
        scheduleMidnightUpdate()
    }

    deinit {
        timer?.invalidate()
    }

    @Published private(set) var todaystamp: String =
        TodaystampService.buildTodaystamp()

    @Published private(set) var maxCalendarDate: Date =
        TodaystampService.buildMaxCalendarDate()

    private var timer: Timer?

    private static func buildTodaystamp() -> String {
        DateInRegion(region: .local).toFormat(
            "yyyy-MM-dd",
            locale: Locale.current
        )
    }

    private static func buildMaxCalendarDate() -> Date {
        DateInRegion(Date(), region: .local)
            .dateByAdding(3, .year)
            .date
    }

    private func scheduleMidnightUpdate() {
        timer?.invalidate()

        let nextMidnight = DateInRegion(region: .local).dateAt(.tomorrowAtStart)

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
        todaystamp = Self.buildTodaystamp()
        maxCalendarDate = Self.buildMaxCalendarDate()

        // Reschedule for tomorrow.
        scheduleMidnightUpdate()
    }

}
