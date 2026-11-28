//
//  CalendarMonthLayout.swift
//  Planner
//
//  Created by Alex Green on 11/26/26.
//

import EventKit
import Foundation
import SwiftData

// MARK: - Day

/// A single planner day within the calendar grid, with its own 24-hour window.
struct CalendarDay {
    /// Index within the month grid (week * 7 + column).
    let gridIndex: Int
    let datestamp: String
    /// Start of the day in the planner's region.
    let start: Date
    /// Start of the next day in the planner's region.
    let end: Date
    let planner: Planner?
}

// MARK: - Item

/// A stable identity for anything displayed on the calendar.
enum CalendarItemID: Hashable {
    case trip(PersistentIdentifier)
    /// Planner events and calendar events (including birthdays).
    case plannerItem(PlannerItemID)
}

/// Something displayed on the calendar. It may cover one or many days.
struct CalendarItem: Identifiable {
    enum Kind {
        case trip(Trip)
        case birthday(PlannerBirthdayItem)
        case ekEvent(EKEvent)
        case plannerEvent(PlannerEvent)
    }

    /// Display priority. Lower values claim lanes first.
    enum Priority: Int, Comparable {
        case trip = 0
        case birthday
        /// All-day calendar events and calendar events that span multiple days.
        case allDay
        case timedCalendar
        case timedUnique
        case untimedUnique
        case timedRoutine
        case untimedRoutine

        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    let id: CalendarItemID
    let kind: Kind
    let title: String
    let priority: Priority
    let isCompleted: Bool
    /// Secondary ordering within a priority.
    let sortDate: Date?
    /// True when the item covers more than one day (across the whole grid, not just one week).
    var spansMultipleDays = false

    var ekEvent: EKEvent? {
        switch kind {
        case .birthday(let item):
            item.ekEvent
        case .ekEvent(let event):
            event
        default:
            nil
        }
    }
}

// MARK: - Layout

/// A run of consecutive columns within a single week that an item covers.
struct CalendarSegment: Identifiable {
    let item: CalendarItem
    let startColumn: Int
    let span: Int
    let lane: Int
    /// True when the item began on an earlier day (i.e. it wrapped onto this week).
    let isContinuation: Bool

    struct ID: Hashable {
        let item: CalendarItemID
        let startColumn: Int
    }

    var id: ID {
        ID(item: item.id, startColumn: startColumn)
    }
}

struct CalendarWeekLayout {
    /// Segments that fit within the visible lanes.
    let segments: [CalendarSegment]
    /// Count of items per column that didn't fit within the visible lanes.
    let remainingCounts: [Int]

    static let empty = CalendarWeekLayout(
        segments: [],
        remainingCounts: Array(repeating: 0, count: 7)
    )
}

struct CalendarMonthLayout {
    let weeks: [CalendarWeekLayout]

    func week(_ index: Int) -> CalendarWeekLayout {
        weeks.indices.contains(index) ? weeks[index] : .empty
    }
}

// MARK: - Builder

enum CalendarMonthLayoutBuilder {
    /// Builds the layout for a month grid.
    ///
    /// - Parameters:
    ///   - days: The month grid (7 per week). Nil entries are padding cells.
    ///   - ekEventItems: Every calendar event overlapping the grid's range, paired with its
    ///     Planner state (used for completion).
    ///   - plannerEvents: Every planner event that may land in the grid.
    ///   - birthdayThumbnails: Contact thumbnails keyed by contact identifier.
    ///   - laneCount: Number of lanes each week can show. The rest are counted as remaining.
    ///   - activeQuery: The active search query, if any.
    static func build(
        days: [CalendarDay?],
        ekEventItems: [PlannerItem],
        birthdayThumbnails: [String: Data],
        plannerEvents: [PlannerEvent],
        laneCount: Int,
        activeQuery: PlannerSearchQuery?
    ) -> CalendarMonthLayout {
        let query = activeQuery?.isDefault == false ? activeQuery : nil

        let validDays = days.compactMap { $0 }
        let indexByDatestamp = Dictionary(
            validDays.map { ($0.datestamp, $0.gridIndex) },
            uniquingKeysWith: { first, _ in first }
        )

        var occurrences: [(item: CalendarItem, indices: [Int])] = []

        /// Insertion order, used as the final tie-breaker when ranking.
        var insertionOrder: [CalendarItemID: Int] = [:]

        func add(_ item: CalendarItem, _ indices: [Int]) {
            guard !indices.isEmpty else { return }

            var item = item
            item.spansMultipleDays = indices.count > 1

            insertionOrder[item.id] = occurrences.count
            occurrences.append((item, indices.sorted()))
        }

        // MARK: Trips

        var tripIndices: [PersistentIdentifier: (Trip, [Int])] = [:]

        for day in validDays {
            guard let trip = day.planner?.trip else { continue }

            if let query, trip.searchQueryScore(query) == nil {
                continue
            }

            tripIndices[trip.persistentModelID, default: (trip, [])].1.append(
                day.gridIndex
            )
        }

        // Note: Sorted by first day so insertion order is deterministic.
        for (id, entry) in tripIndices.sorted(by: {
            ($0.value.1.first ?? 0) < ($1.value.1.first ?? 0)
        }) {
            add(
                CalendarItem(
                    id: .trip(id),
                    kind: .trip(entry.0),
                    title: entry.0.title,
                    priority: .trip,
                    isCompleted: false,
                    sortDate: nil
                ),
                entry.1
            )
        }

        // MARK: Calendar Events

        for ekEventItem in ekEventItems {
            guard let ekEvent = ekEventItem.ekEvent,
                let startDate = ekEvent.startDate,
                let endDate = ekEvent.endDate
            else { continue }

            var indices: [Int]

            if ekEvent.isAllDay {
                indices = allDayDatestamps(
                    startDate: startDate,
                    endDate: endDate,
                    timeZoneId: ekEvent.timeZone?.identifier
                )
                .compactMap { indexByDatestamp[$0] }
            } else {
                indices = validDays.filter { day in
                    (startDate < day.end && endDate > day.start)
                        || (startDate >= day.start && startDate < day.end)
                }
                .map(\.gridIndex)
            }

            if let query {
                indices = indices.filter { index in
                    guard let day = days[index] else { return false }
                    return ekEvent.searchQueryScore(query, in: day.datestamp)
                        != nil
                }
            }

            guard let firstIndex = indices.min(),
                let firstDay = days[firstIndex]
            else { continue }

            let id = CalendarItemID.plannerItem(ekEventItem.id)
            let title = ekEvent.title ?? ""

            if let contactId = ekEvent.birthdayContactIdentifier {
                add(
                    CalendarItem(
                        id: id,
                        kind: .birthday(
                            PlannerBirthdayItem(
                                ekEvent: ekEvent,
                                contactIdentifier: contactId,
                                thumbnailData: birthdayThumbnails[contactId]
                            )
                        ),
                        title: title,
                        priority: .birthday,
                        isCompleted: false,
                        sortDate: nil
                    ),
                    indices
                )
                continue
            }

            let isTimedSingleDay =
                !ekEvent.isAllDay
                && indices.count == 1
                && startDate >= firstDay.start

            if isTimedSingleDay {
                let isCompleted = ekEventItem.isCompleted

                // Note: Searches include completed events.
                if isCompleted && query == nil {
                    continue
                }

                add(
                    CalendarItem(
                        id: id,
                        kind: .ekEvent(ekEvent),
                        title: title,
                        priority: .timedCalendar,
                        isCompleted: isCompleted,
                        sortDate: startDate
                    ),
                    indices
                )
            } else {
                add(
                    CalendarItem(
                        id: id,
                        kind: .ekEvent(ekEvent),
                        title: title,
                        priority: .allDay,
                        isCompleted: false,
                        sortDate: nil
                    ),
                    indices
                )
            }
        }

        // MARK: Planner Events

        for event in plannerEvents {
            guard event.eKEventContext == nil else { continue }

            let routineContext = event.routineEventRecordContext
            let isRoutine = routineContext != nil

            // Routine events are only shown when edited or while searching.
            if let routineContext, !routineContext.isVariant, query == nil {
                continue
            }

            if event.isCompleted && query == nil {
                continue
            }

            var indices: [Int]

            if let time = event.time {
                indices = validDays.filter {
                    time >= $0.start && time < $0.end
                }
                .map(\.gridIndex)
            } else if let datestamp = event.datestamp,
                let index = indexByDatestamp[datestamp]
            {
                indices = [index]
            } else {
                continue
            }

            if let query {
                indices = indices.filter { index in
                    guard let day = days[index] else { return false }
                    return event.searchQueryScore(query, in: day.datestamp)
                        != nil
                }
            }

            let isTimed = event.time != nil
            let priority: CalendarItem.Priority =
                switch (isTimed, isRoutine) {
                case (true, false): .timedUnique
                case (false, false): .untimedUnique
                case (true, true): .timedRoutine
                case (false, true): .untimedRoutine
                }

            add(
                CalendarItem(
                    id: .plannerItem(.plannerEvent(event.stableId)),
                    kind: .plannerEvent(event),
                    title: event.title,
                    priority: priority,
                    isCompleted: event.isCompleted,
                    sortDate: event.time ?? event.sortDate
                ),
                indices
            )
        }

        // MARK: Rank

        occurrences.sort { lhs, rhs in
            let l = lhs.item
            let r = rhs.item

            if l.priority != r.priority {
                return l.priority < r.priority
            }

            if let lDate = l.sortDate, let rDate = r.sortDate, lDate != rDate {
                return lDate < rDate
            }

            if l.title != r.title {
                return l.title.localizedStandardCompare(r.title)
                    == .orderedAscending
            }

            return (insertionOrder[l.id] ?? 0) < (insertionOrder[r.id] ?? 0)
        }

        // MARK: Layout Weeks

        let weekCount = days.count / 7

        let weeks = (0..<weekCount).map { week in
            layoutWeek(
                week: week,
                occurrences: occurrences,
                laneCount: laneCount
            )
        }

        return CalendarMonthLayout(weeks: weeks)
    }

    // MARK: - Week Layout

    private static func layoutWeek(
        week: Int,
        occurrences: [(item: CalendarItem, indices: [Int])],
        laneCount: Int
    ) -> CalendarWeekLayout {
        let weekStart = week * 7
        let weekRange = weekStart..<(weekStart + 7)

        // Split each occurrence into runs of consecutive columns within this week.
        var pending:
            [(
                rank: Int, item: CalendarItem, start: Int, span: Int,
                isContinuation: Bool
            )] = []

        for (rank, occurrence) in occurrences.enumerated() {
            let columns =
                occurrence.indices
                .filter { weekRange.contains($0) }
                .map { $0 - weekStart }

            guard var runStart = columns.first,
                let firstIndex = occurrence.indices.first
            else { continue }
            var previous = runStart

            func isContinuation(_ start: Int) -> Bool {
                weekStart + start > firstIndex
            }

            for column in columns.dropFirst() {
                if column == previous + 1 {
                    previous = column
                    continue
                }

                pending.append(
                    (
                        rank, occurrence.item, runStart,
                        previous - runStart + 1, isContinuation(runStart)
                    )
                )
                runStart = column
                previous = column
            }

            pending.append(
                (
                    rank, occurrence.item, runStart,
                    previous - runStart + 1, isContinuation(runStart)
                )
            )
        }

        // Higher priority first. Within a priority, longer spans first so they claim
        // consistent lanes across the week.
        pending.sort { lhs, rhs in
            if lhs.item.priority != rhs.item.priority {
                return lhs.item.priority < rhs.item.priority
            }

            if lhs.span != rhs.span {
                return lhs.span > rhs.span
            }

            if lhs.start != rhs.start {
                return lhs.start < rhs.start
            }

            return lhs.rank < rhs.rank
        }

        var occupied: [[Bool]] = []
        var totalCounts = Array(repeating: 0, count: 7)
        var visibleCounts = Array(repeating: 0, count: 7)
        var segments: [CalendarSegment] = []

        for entry in pending {
            let columns = entry.start..<(entry.start + entry.span)

            var lane = 0
            while lane < occupied.count,
                columns.contains(where: { occupied[lane][$0] })
            {
                lane += 1
            }

            if lane == occupied.count {
                occupied.append(Array(repeating: false, count: 7))
            }

            for column in columns {
                occupied[lane][column] = true
                totalCounts[column] += 1
            }

            guard lane < laneCount else { continue }

            for column in columns {
                visibleCounts[column] += 1
            }

            segments.append(
                CalendarSegment(
                    item: entry.item,
                    startColumn: entry.start,
                    span: entry.span,
                    lane: lane,
                    isContinuation: entry.isContinuation
                )
            )
        }

        return CalendarWeekLayout(
            segments: segments,
            remainingCounts: zip(totalCounts, visibleCounts).map { $0 - $1 }
        )
    }

    // MARK: - Helpers

    private static func allDayDatestamps(
        startDate: Date,
        endDate: Date,
        timeZoneId: String?
    ) -> [String] {
        guard
            let timeZone = TimeZone(
                identifier: timeZoneId ?? TimeZone.current.identifier
            )
        else {
            return []
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        var current = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        var datestamps: [String] = []

        while current <= end {
            datestamps.append(
                DatestampFormatter.datestamp(from: current, timeZone: timeZone)
            )

            guard
                let next = calendar.date(byAdding: .day, value: 1, to: current)
            else { break }

            current = next
        }

        return datestamps
    }
}
