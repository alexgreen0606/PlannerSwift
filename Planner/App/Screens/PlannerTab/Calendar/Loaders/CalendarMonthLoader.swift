//
//  CalendarMonthLoader.swift
//  Planner
//
//  Created by Alex Green on 11/26/26.
//

import Combine
import EventKit
import SwiftData
import SwiftDate
import SwiftUI
import os

/// Loads everything a calendar month needs and structures it into a `CalendarMonthLayout`.
///
/// One EventKit fetch and one SwiftData query cover the whole grid. Each day keeps its own
/// 24-hour window based on its planner's region.
///
/// Like the planner list preview, this loader is read-only: it never creates `EkEventPlannerState`s.
struct CalendarMonthLoaderView<Content: View>: View {
    private let datestamps: [String?]
    /// Number of lanes each week row can show.
    private let laneCount: Int
    private let settings: Settings
    private let content: (CalendarMonthLayout) -> Content

    init(
        datestamps: [String?],
        laneCount: Int,
        settings: Settings,
        @ViewBuilder content: @escaping (CalendarMonthLayout) -> Content
    ) {
        self.datestamps = datestamps
        self.laneCount = laneCount
        self.settings = settings
        self.content = content

        _planners = Query(
            filter: Planner.planners(
                datestamps: Set(datestamps.compactMap { $0 })
            )
        )
    }

    @EnvironmentObject private var calendarService: CalendarService

    @Query private var planners: [Planner]

    private var days: [CalendarDay?] {
        let plannersByDatestamp = Dictionary(
            planners.map { ($0.datestamp, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let homeRegion = settings.homeRegion

        return datestamps.enumerated().map { index, datestamp in
            guard let datestamp else { return nil }

            let planner = plannersByDatestamp[datestamp]
            let startOfDay =
                planner?.startOfDay(settings: settings)
                ?? datestamp.startOfDay(in: homeRegion)

            return CalendarDay(
                gridIndex: index,
                datestamp: datestamp,
                start: startOfDay.date,
                end: (startOfDay + 1.days).date,
                planner: planner
            )
        }
    }

    // MARK: Body

    var body: some View {
        CalendarMonthEventLoaderView(
            days: days,
            laneCount: laneCount,
            calendarService: calendarService,
            settings: settings,
            content: content
        )
    }
}

// MARK: - Event Loader

private struct CalendarMonthEventLoaderView<Content: View>: View {
    private let days: [CalendarDay?]
    private let laneCount: Int
    private let settings: Settings
    private let content: (CalendarMonthLayout) -> Content
    private let range: DateInterval?

    init(
        days: [CalendarDay?],
        laneCount: Int,
        calendarService: CalendarService,
        settings: Settings,
        content: @escaping (CalendarMonthLayout) -> Content
    ) {
        self.days = days
        self.laneCount = laneCount
        self.settings = settings
        self.content = content

        let validDays = days.compactMap { $0 }
        let range: DateInterval? = {
            guard let start = validDays.map(\.start).min(),
                let end = validDays.map(\.end).max(),
                start < end
            else { return nil }

            return DateInterval(start: start, end: end)
        }()

        self.range = range

        _ekEventLoader = StateObject(
            wrappedValue: CalendarMonthEkEventLoader(
                calendarService: calendarService,
                settings: settings,
                range: range
            )
        )

        let datestamps = validDays.map(\.datestamp)

        _plannerEvents = Query(
            filter: PlannerEvent.calendarMonthEvents(
                start: range?.start ?? .distantPast,
                end: range?.end ?? .distantPast,
                minDatestamp: datestamps.min() ?? "",
                maxDatestamp: datestamps.max() ?? ""
            ),
            sort: \.sortDate
        )
    }

    @EnvironmentObject private var calendarService: CalendarService

    @Query private var plannerEvents: [PlannerEvent]

    @StateObject private var ekEventLoader: CalendarMonthEkEventLoader

    /// The `@StateObject` keeps the range it was created with. This key tells it to reload when the
    /// month's day windows move (e.g. planners load with their own regions) or when the visible
    /// calendars change, since neither posts `EKEventStoreChanged`.
    private var reloadKey: String {
        calendarService.ekEventReloadKey(range: range, settings: settings)
    }

    // MARK: Body

    var body: some View {
        // Note: Matches by identifier so the predicate stays small across a whole month.
        EkEventPlannerStateLoaderView(
            ekEvents: ekEventLoader.ekEvents,
            matching: .externalIdentifiers
        ) { ekEventItems in
            CalendarMonthLayoutView(
                days: days,
                laneCount: laneCount,
                ekEventItems: ekEventItems,
                birthdayThumbnails: ekEventLoader.birthdayThumbnails,
                plannerEvents: plannerEvents,
                content: content
            )
        }
        .onChange(of: reloadKey) { _, _ in
            ekEventLoader.update(range: range)
        }
    }
}

// MARK: - Layout

private struct CalendarMonthLayoutView<Content: View>: View {
    let days: [CalendarDay?]
    let laneCount: Int
    let ekEventItems: [PlannerItem]
    let birthdayThumbnails: [String: Data]
    let plannerEvents: [PlannerEvent]
    let content: (CalendarMonthLayout) -> Content

    @EnvironmentObject private var plannerService: PlannerService

    var body: some View {
        content(layout)
    }

    private var layout: CalendarMonthLayout {
        let state = calendarSignposter.beginInterval("CalendarMonthLayout")
        defer { calendarSignposter.endInterval("CalendarMonthLayout", state) }

        return CalendarMonthLayoutBuilder.build(
            days: days,
            ekEventItems: ekEventItems,
            birthdayThumbnails: birthdayThumbnails,
            plannerEvents: plannerEvents,
            laneCount: laneCount,
            activeQuery: plannerService.activeQuery
        )
    }
}

// MARK: - EventKit Loader

private let calendarSignposter = OSSignposter(
    subsystem: Bundle.main.bundleIdentifier ?? "Planner",
    category: "Calendar"
)

/// Fetches every calendar event overlapping a month grid's range in a single EventKit query.
@MainActor
final class CalendarMonthEkEventLoader: ObservableObject {
    private let calendarService: CalendarService
    private let settings: Settings
    private var range: DateInterval?
    private var cancellables: Set<AnyCancellable> = []

    @Published private(set) var ekEvents: [EKEvent] = []

    /// Contact thumbnails for birthday events, keyed by contact identifier.
    @Published private(set) var birthdayThumbnails: [String: Data] = [:]

    init(
        calendarService: CalendarService,
        settings: Settings,
        range: DateInterval?
    ) {
        self.calendarService = calendarService
        self.settings = settings
        self.range = range

        reload()

        calendarService.ekEventChangesPublisher
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.reload()
            }
            .store(in: &cancellables)
    }

    func update(range: DateInterval?) {
        self.range = range
        reload()
    }

    func reload() {
        guard let range else {
            ekEvents = []
            birthdayThumbnails = [:]
            return
        }

        let state = calendarSignposter.beginInterval("CalendarMonthEkFetch")
        defer { calendarSignposter.endInterval("CalendarMonthEkFetch", state) }

        let fetchedEvents = calendarService.fetchEkEvents(
            in: range,
            settings: settings
        )

        birthdayThumbnails = calendarService.birthdayThumbnails(
            for: fetchedEvents
        )
        ekEvents = fetchedEvents
    }
}
