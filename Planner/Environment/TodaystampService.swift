//
//  TodaystampService.swift
//  Planner
//
//  Created by Alex Green on 12/5/25.
//

import Combine
import SwiftDate
import SwiftUI

@MainActor
class TodaystampService: ObservableObject {
    init() {
        scheduleMidnightUpdate()
    }

    deinit {
        timer?.invalidate()
    }

    @AppStorage("keepPastEventsDuration") private var keepPastEventsDuration:
        KeepPastEventsDuration =
            .oneMonth

    @Published private(set) var todaystamp: String =
        TodaystampService.buildTodaystamp()

    @Published private(set) var next7Datestamps: [String] =
        TodaystampService.buildNext7Datestamps()
    
    var datePickerBounds: ClosedRange<Date> {
        keepPastEventsDuration.cutoffDate...maxCalendarDate
    }

    var multiDatePickerBounds: Range<Date> {
        keepPastEventsDuration.cutoffDate..<maxCalendarDate
    }
    
    private var maxCalendarDate: Date =
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

    private static func buildNext7Datestamps() -> [String] {
        let today = DateInRegion(region: .local)

        return (0..<7).map { index in
            today
                .dateByAdding(index, .day)
                .toFormat("yyyy-MM-dd")
        }
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
        next7Datestamps = Self.buildNext7Datestamps()

        // Reschedule for tomorrow.
        scheduleMidnightUpdate()
    }
}
