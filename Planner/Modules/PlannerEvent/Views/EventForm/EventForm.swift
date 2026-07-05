//
//  EventForm.swift
//  Planner
//
//  Created by Alex Green on 1/29/26.
//

import EventKit
import EventKitUI
import SwiftData
import SwiftDate
import SwiftUI

struct EventFormView: View {
    private let sourcePlannerEvent: PlannerEvent?
    private let sourcePlanner: Planner?
    private let settings: Settings

    // MARK: Create Planner Event (Dashboard)
    init(settings: Settings) {
        self.sourcePlannerEvent = nil
        self.sourcePlanner = nil
        self.settings = settings

        self._draftPlannerEvent = State(initialValue: DraftPlannerEvent())
    }

    // MARK: Edit Planner Event (Planner)
    init(
        plannerEvent: PlannerEvent,
        planner: Planner,
        ekEventStore: EKEventStore,
        settings: Settings
    ) {
        self.sourcePlannerEvent = plannerEvent
        self.sourcePlanner = planner
        self.settings = settings

        self._draftPlannerEvent = State(
            initialValue:
                DraftPlannerEvent(
                    plannerEvent: plannerEvent,
                    planner: planner,
                    ekEventStore: ekEventStore,
                    settings: settings
                )
        )
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.showToast) private var showToast
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var plannerService: PlannerService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    @State private var draftPlannerEvent: DraftPlannerEvent

    private var isCreateForm: Bool {
        sourcePlannerEvent == nil
    }

    private var showCalendarEventSheetBinding: Binding<Bool> {
        Binding(
            get: {
                draftPlannerEvent.ekEvent != nil
            },
            set: { newValue in
                if !newValue {
                    draftPlannerEvent.ekEvent = nil
                }
            }
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            if !showCalendarEventSheetBinding.wrappedValue {
                PlannerEventFormView(
                    draftPlannerEvent: $draftPlannerEvent,
                    sourcePlannerEvent: sourcePlannerEvent,
                    sourcePlanner: sourcePlanner,
                    settings: settings,
                    showNotification: showNotification
                )
            }
        }
        .sheet(isPresented: showCalendarEventSheetBinding) {
            if let ekEvent = draftPlannerEvent.ekEvent {
                calendarEventForm(for: ekEvent)
                    .toolbar {
                        ToolbarSpacer(placement: .bottomBar)

                        ToolbarItem(placement: .bottomBar) {
                            Button(
                                "Remove from Calendar",
                                action: removeEventFromCalendar
                            )
                            .fontWeight(.medium)
                        }
                    }
                    .interactiveDismissDisabled(true)
            }
        }
        .presentationBackground(Color.sheetBackground)
        .interactiveDismissDisabled(true)
    }

    // MARK: - View Builders

    private func calendarEventForm(for event: EKEvent) -> some View {
        EditCalendarEventFormView(
            event: event,
            ekEventStore: calendarService.ekEventStore
        ) { action, event in
            guard action != .canceled else {
                if let sourcePlannerEvent,
                    sourcePlannerEvent.title.trimmed.isEmpty
                {
                    // The source event had an empty title. Delete it.
                    modelContext.deletePlannerEvent(
                        sourcePlannerEvent,
                        ekEventStore: calendarService.ekEventStore
                    )
                }
                dismiss()
                return
            }

            saveCalendarEvent(event)
        }
        .tint(accentColor.swiftUiColor)
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Functions

    private func saveCalendarEvent(_ event: EKEvent?) {
        let destinationDatestamps = modelContext.handleCalendarEventChange(
            event,
            sourcePlannerEvent: sourcePlannerEvent,
            sourcePlanner: sourcePlanner,
            plannerService: plannerService,
            settings: settings
        )

        dismiss()

        showNotification(destinationDatestamps: destinationDatestamps)
    }

    private func showNotification(destinationDatestamps: Set<String>) {
        guard let earliestDatestamp = destinationDatestamps.sorted().first
        else { return }

        guard let sourceDatestamp = sourcePlanner?.datestamp else {
            showToast(
                Toast(
                    title:
                        "Successfully created event!",
                    subtitle:
                        "\(earliestDatestamp.dateWithYear) | \(earliestDatestamp.weekday)",
                    iconConfig: IconConfig(
                        name: "calendar.day.timeline.leading",
                        primaryColor: Color.label,
                        secondaryColor: Color.secondary
                    ),
                    variant: .tab,
                    action: {
                        plannerCoverStore.context = PlannerCoverContext(
                            datestamp: earliestDatestamp
                        )
                    }
                )
            )
            return
        }

        guard !destinationDatestamps.contains(sourceDatestamp) else { return }

        let leftArrowColor =
            earliestDatestamp > sourceDatestamp
            ? Color.secondary : Color.label
        let rightArrowColor =
            earliestDatestamp > sourceDatestamp
            ? Color.label : Color.secondary

        showToast(
            Toast(
                title: "Successfully moved event!",
                subtitle:
                    "\(earliestDatestamp.dateWithYear) | \(earliestDatestamp.weekday)",
                iconConfig: IconConfig(
                    name: "arrow.left.arrow.right",
                    primaryColor: leftArrowColor,
                    secondaryColor: rightArrowColor
                ),
                action: {
                    plannerCoverStore.context = PlannerCoverContext(
                        datestamp: earliestDatestamp
                    )
                }
            )
        )
    }

    private func removeEventFromCalendar() {
        // Note: EventKit does not give access to the updated EKEvent.
        // Therefore we cannot sync the planner event to the draft calendar event.
        draftPlannerEvent.ekEvent = nil
    }
}
