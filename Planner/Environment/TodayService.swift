//
//  TodayService.swift
//  Planner
//
//  Created by Alex Green on 12/5/25.
//

import Combine
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

        todayPlanner = modelContext.getPlanner(
            for: todaystamp
        )

        self.todaystamp = todaystamp

        scheduleMidnightUpdate()
    }

    deinit {
        timer?.invalidate()
    }

    private var maxCalendarDate: Date =
        TodayService.makeMaxCalendarDate()

    private var timer: Timer?

    @Published private(set) var todaystamp: String
    
    @Published private(set) var todayPlanner: Planner

    var datePickerBounds: ClosedRange<Date> {
        settings.keepPastEventsDuration.cutoffDate...maxCalendarDate
    }

    var multiDatePickerBounds: Range<Date> {
        settings.keepPastEventsDuration.cutoffDate..<maxCalendarDate
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
        maxCalendarDate = Self.makeMaxCalendarDate()
        todayPlanner = modelContext.getPlanner(for: todaystamp)

        // Reschedule for the next midnight.
        scheduleMidnightUpdate()
    }
}
