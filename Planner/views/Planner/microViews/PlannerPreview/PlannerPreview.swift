//
//  PlannerPreview.swift
//  Planner
//
//  Created by Alex Green on 12/25/25.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI
import WeatherKit
import WrappingHStack

// Clean

struct PlannerPreviewView: View {
    let type: PlannerPreviewType
    let searchQuery: PlannerSearchQuery?
    let planner: Planner
    let plannerStartOfDay: DateInRegion
    let plannerLocation: Location?
    let plannerEvents: [PlannerEvent]
    let plannerChipEvents: [EKEvent]
    let settings: PlannerSettings

    private let maxPreviewEvents = 5

    @EnvironmentObject private var plannerCoverManager: PlannerCoverManager

    // MARK: - Computed Variables

    private var filteredPlannerEvents: [PlannerEvent] {
        plannerEvents.filter(shouldShowPlannerEvent)
    }

    private var filteredChipEvents: [EKEvent] {
        plannerChipEvents.filter(shouldShowChipEvent)
    }

    private var timedPlannerEvents: [PlannerEvent] {
        filteredPlannerEvents.filter { $0.hasTime }
    }

    private var untimedPlannerEvents: [PlannerEvent] {
        filteredPlannerEvents.filter { !$0.hasTime }
    }

    private var previewAllDayEvents: [EKEvent] {
        Array(filteredChipEvents.prefix(maxPreviewEvents))
    }

    private var sortedPreviewPlannerEvents: [PlannerEvent] {
        let slots = max(0, maxPreviewEvents - previewAllDayEvents.count)

        let timed = Array(timedPlannerEvents.prefix(slots))
        let remaining = slots - timed.count
        let untimed = untimedPlannerEvents.prefix(max(0, remaining))

        return (timed + untimed).sorted { $0.sortDate < $1.sortDate }
    }

    private var remainingPlansLabel: String {
        let totalEventCount =
            plannerChipEvents.count + filteredPlannerEvents.count

        let previewCount =
            previewAllDayEvents.count + sortedPreviewPlannerEvents.count

        let remainingCount = totalEventCount - previewCount

        if remainingCount == 0 {
            if previewCount > 0 {
                return "No more plans"
            }
            return "No plans"
        }

        return "\(remainingCount) more plan\(remainingCount == 1 ? "" : "s")"
    }

    private var hasPlans: Bool {
        (previewAllDayEvents.count + sortedPreviewPlannerEvents.count) > 0
    }

    // MARK: - Body

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .top) {
                PlannerDateInfoView(
                    plannerStartOfDay: plannerStartOfDay,
                    isThisWeek: type.isThisWeek
                )

                Spacer()

                if type == .search {
                    weatherInfo
                }
            }

            AllDayEventListView(
                events: plannerChipEvents,
                settings: settings
            )

            PlannerEventListView(
                plannerRegion: plannerStartOfDay.region,
                events: sortedPreviewPlannerEvents
            )

            remainingPlansIndicator
            emptyPlannerIndicator

            if type == .planner {
                weatherInfo
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            plannerCoverManager.context = PlannerCoverContext(
                datestamp: planner.datestamp
            )
        }

        if type == .planner {
            content
                .padding(.top)
                .padding(.horizontal)
                .padding(.bottom, 12)
                .frame(width: 240)
                .frame(height: 330, alignment: .top)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.cardBackground)
                )
        } else {
            content
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - View Builders

    private var weatherInfo: some View {
        WeatherInfoView(
            previewType: type,
            planner: planner,
            plannerStartOfDay: plannerStartOfDay,
            plannerLocation: plannerLocation,
            settings: settings
        )
    }

    @ViewBuilder
    private var remainingPlansIndicator: some View {
        if hasPlans {
            Text(remainingPlansLabel)
                .font(
                    .system(size: 12, weight: .heavy, design: .rounded)
                )
                .foregroundStyle(Color.secondary)
        }
    }

    @ViewBuilder
    private var emptyPlannerIndicator: some View {
        if type == .planner {
            VStack {
                if !hasPlans {
                    Text(remainingPlansLabel)
                        .font(
                            .system(size: 12, weight: .heavy, design: .rounded)
                        )
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .center
            )
        }
    }

    // MARK: - Functions

    private func shouldShowPlannerEvent(_ event: PlannerEvent) -> Bool {
        if isCalendarHidden(event.calendarEvent?.calendar) {
            return false
        }

        // Show every unchecked event when there is no search text.
        guard let searchQuery, !searchQuery.text.isEmpty else {
            return !event.isChecked
        }

        let lowercasedSearchText = searchQuery.text.lowercased()

        if event.title.lowercased().contains(lowercasedSearchText) {
            return true
        }

        if let location = event.location,
            location.name.lowercased().contains(lowercasedSearchText)
        {
            return true
        }

        return false
    }

    private func shouldShowChipEvent(_ event: EKEvent) -> Bool {
        if isCalendarHidden(event.calendar) {
            return false
        }

        // Show every chip event when there is no search text.
        guard let searchQuery, !searchQuery.text.isEmpty else {
            return true
        }

        if searchQuery.text.isEmpty {
            return true
        }

        let lowercasedSearchText = searchQuery.text.lowercased()

        if event.title.lowercased().contains(lowercasedSearchText) {
            return true
        }

        if let location = event.location,
            location.lowercased().contains(lowercasedSearchText)
        {
            return true
        }

        return false
    }

    private func isCalendarHidden(_ calendar: EKCalendar?) -> Bool {
        guard let searchQuery, let calendar else {
            return false
        }

        return !searchQuery.filteredCalendarIds.isEmpty
            && searchQuery.filteredCalendarIds.contains(
                calendar.calendarIdentifier
            )
    }

}
