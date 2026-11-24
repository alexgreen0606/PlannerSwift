//
//  EventFormSheet.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import EventKit
import SwiftUI

extension View {
    /// Presents the event form for a `PlannerItem` in a single sheet.
    /// "Add to Calendar" and "Remove from Calendar" cross-fade between the Planner and calendar forms
    /// without closing the sheet.
    func eventFormSheet(
        context: Binding<EventSheetContext?>,
        planner: Planner,
        settings: Settings,
        namespace: Namespace.ID
    ) -> some View {
        sheet(item: context) { context in
            EventFormContainerView(
                context: context,
                planner: planner,
                settings: settings
            )
            .navigationTransition(
                .zoom(
                    sourceID: context.id,
                    in: namespace
                )
            )
        }
    }
}

/// Holds the currently visible form and cross-fades between them.
private struct EventFormContainerView: View {
    private let item: PlannerItem
    private let planner: Planner
    private let settings: Settings

    init(
        context: EventSheetContext,
        planner: Planner,
        settings: Settings
    ) {
        self.item = context.item
        self.planner = planner
        self.settings = settings

        self._form = State(initialValue: context.initialForm)
    }

    @State private var form: EventSheetContext.Form

    private var isEditable: Bool {
        if case .viewCalendar = form {
            return false
        }

        return true
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            switch form {
            case .planner(let draft):
                PlannerEventFormView(
                    item: item,
                    initialDraft: draft,
                    planner: planner,
                    settings: settings,
                    addToCalendar: { draft, ekEvent in
                        switchForm(
                            to: .calendar(
                                ekEvent: ekEvent,
                                plannerDraft: draft
                            )
                        )
                    }
                )
                .background(Color.sheetBackground)
                .transition(.opacity)

            case .calendar(let ekEvent, let plannerDraft):
                CalendarEventFormView(
                    item: item,
                    ekEvent: ekEvent,
                    planner: planner,
                    settings: settings,
                    removeFromCalendar: {
                        // Discard draft values applied by the Planner form before reading the event.
                        ekEvent.rollback()

                        switchForm(
                            to: .planner(
                                draft: plannerDraft
                                    ?? DraftPlannerEvent(
                                        ekEvent: ekEvent
                                    )
                            )
                        )
                    }
                )
                .background(Color.sheetBackground)
                .transition(.opacity)

            case .viewCalendar(let ekEvent):
                ViewCalendarEventFormView(ekEvent: ekEvent)
                    .ignoresSafeArea()
                    .presentationDetents([.height(400)])
            }
        }
        .presentationBackground(Color.clear)
        .interactiveDismissDisabled(isEditable)
    }

    // MARK: - Functions

    private func switchForm(to newForm: EventSheetContext.Form) {
        withAnimation(.easeInOut(duration: 0.3)) {
            form = newForm
        }
    }
}
