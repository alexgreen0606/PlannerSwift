//
//  TodayService.swift
//  Planner
//
//  Created by Alex Green on 12/5/25.
//

import Combine
import Fuse
import SwiftData
import SwiftDate
import SwiftUI

@MainActor
final class TodayService: ObservableObject {
    private let settings: Settings
    private let modelContext: ModelContext

    init(settings: Settings, modelContext: ModelContext) {
        self.settings = settings
        self.modelContext = modelContext

        let todaystamp = TodayService.makeTodaystamp()

        next30Datestamps = getNext30Datestamps()

        let todayPlanner = modelContext.getPlanner(
            for: todaystamp
        )

        self.todayPlanner = todayPlanner
        self.todaystamp = todaystamp

        self.defaultSearchQuery = PlannerSearchQuery(
            text: "",
            calendarIds: [],
            past: false,
            todayStartOfDay: todayPlanner.startOfDay(settings: settings),
            fuse: Fuse()
        )

        scheduleMidnightUpdate()
    }

    deinit {
        timer?.invalidate()
    }

    private var maxCalendarDate: Date =
        TodayService.makeMaxCalendarDate()

    private var timer: Timer?

    private var todayPlanner: Planner

    @Published private(set) var todaystamp: String

    @Published private(set) var next30Datestamps: [String]

    @Published private(set) var defaultSearchQuery: PlannerSearchQuery

    var datePickerBounds: ClosedRange<Date> {
        settings.keepPastEventsDuration.cutoffDate...maxCalendarDate
    }

    var multiDatePickerBounds: Range<Date> {
        settings.keepPastEventsDuration.cutoffDate..<maxCalendarDate
    }

    var todayStartOfDay: DateInRegion {
        todayPlanner.startOfDay(settings: settings)
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
        next30Datestamps = getNext30Datestamps()
        maxCalendarDate = Self.makeMaxCalendarDate()
        todayPlanner = modelContext.getPlanner(for: todaystamp)

        defaultSearchQuery = PlannerSearchQuery(
            text: "",
            calendarIds: [],
            past: false,
            todayStartOfDay: todayPlanner.startOfDay(settings: settings),
            fuse: Fuse()
        )

        // Reschedule for the next midnight.
        scheduleMidnightUpdate()
    }
}
