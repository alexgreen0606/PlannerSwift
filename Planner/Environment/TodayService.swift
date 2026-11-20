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

        let minDatestamp =
            "\(Int(todaystamp.prefix(4))! - 2)\(todaystamp.dropFirst(4))"
        let maxDatestamp =
            "\(Int(todaystamp.prefix(4))! + 2)\(todaystamp.dropFirst(4))"

        CalendarDatestampCache.shared.update(
            currentMonthstamp: todaystamp.monthstamp
        )

        next30Datestamps = getNext30Datestamps()

        let todayPlanner = modelContext.getPlanner(
            for: todaystamp
        )

        self.minPlanner = modelContext.getPlanner(
            for: minDatestamp
        )

        self.maxPlanner = modelContext.getPlanner(
            for: maxDatestamp
        )

        self.todayPlanner = todayPlanner
        self.todaystamp = todaystamp

        scheduleMidnightUpdate()
    }

    deinit {
        timer?.invalidate()
    }

    private var timer: Timer?

    private var todayPlanner: Planner
    private var minPlanner: Planner
    private var maxPlanner: Planner

    @Published private(set) var todaystamp: String

    @Published private(set) var next30Datestamps: [String]

    var datePickerBounds: ClosedRange<Date> {
        minStartOfDay.date...maxStartOfDay.date
    }

    var multiDatePickerBounds: Range<Date> {
        minStartOfDay.date..<maxStartOfDay.date
    }

    var todayStartOfDay: DateInRegion {
        todayPlanner.startOfDay(settings: settings)
    }

    var minStartOfDay: DateInRegion {
        minPlanner.startOfDay(settings: settings)
    }

    var maxStartOfDay: DateInRegion {
        maxPlanner.startOfDay(settings: settings)
    }

    var monthstamp: String {
        todaystamp.monthstamp
    }

    // MARK: - Builder Functions

    private static func makeTodaystamp() -> String {
        DateInRegion(region: .local).toFormat(
            "yyyy-MM-dd",
            locale: Locale.current
        )
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
        let previousMonthstamp = monthstamp

        todaystamp = Self.makeTodaystamp()
        
        todayPlanner = modelContext.getPlanner(for: todaystamp)

        if monthstamp != previousMonthstamp {
            CalendarDatestampCache.shared.update(
                currentMonthstamp: monthstamp
            )
        }

        next30Datestamps = getNext30Datestamps()

        let minDatestamp =
            "\(Int(todaystamp.prefix(4))! - 2)\(todaystamp.dropFirst(4))"
        let maxDatestamp =
            "\(Int(todaystamp.prefix(4))! + 2)\(todaystamp.dropFirst(4))"

        minPlanner = modelContext.getPlanner(
            for: minDatestamp
        )

        maxPlanner = modelContext.getPlanner(
            for: maxDatestamp
        )

        scheduleMidnightUpdate()
    }
}
