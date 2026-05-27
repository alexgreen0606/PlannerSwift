//
//  TodayService.swift
//  Planner
//
//  Created by Alex Green on 12/5/25.
//

import Combine
import SwiftDate
import SwiftUI

@MainActor
final class TodayService: ObservableObject {
    init() {
        scheduleMidnightUpdate()
    }

    deinit {
        timer?.invalidate()
    }
    
    private var maxCalendarDate: Date =
        TodayService.makeMaxCalendarDate()

    private var timer: Timer?

    @AppStorage("keepPastEventsDuration") private var keepPastEventsDuration:
        KeepPastEventsDuration =
            .oneMonth

    @Published private(set) var todaystamp: String =
        TodayService.makeTodaystamp()

    @Published private(set) var next7Datestamps: [String] =
        TodayService.makeNext7Datestamps()

    var datePickerBounds: ClosedRange<Date> {
        keepPastEventsDuration.cutoffDate...maxCalendarDate
    }

    var multiDatePickerBounds: Range<Date> {
        keepPastEventsDuration.cutoffDate..<maxCalendarDate
    }

    // MARK: - Builder Functions

    private static func makeTodaystamp() -> String {
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

    private static func makeNext7Datestamps() -> [String] {
        let today = DateInRegion(region: .local)

        return (0..<7).map { offset in
            today
                .dateByAdding(offset, .day)
                .toFormat("yyyy-MM-dd")
        }
    }

    // MARK: - Schedule Functions

    private func scheduleMidnightUpdate() {
        timer?.invalidate()

        let nextMidnight = DateInRegion(region: .local).dateAt(.tomorrowAtStart)

        timer = Timer(
            fire: nextMidnight.date,
            interval: 0,
            repeats: false
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.updateStamp()
            }
        }

        RunLoop.main.add(timer!, forMode: .common)
    }

    private func updateStamp() {
        todaystamp = Self.makeTodaystamp()
        next7Datestamps = Self.makeNext7Datestamps()
        maxCalendarDate = Self.makeMaxCalendarDate()

        // Reschedule for the next midnight.
        scheduleMidnightUpdate()
    }
}
