//
//  PlannerList.swift
//  Planner
//
//  Created by Alex Green on 3/11/26.
//

import EventKit
import SwiftDate
import SwiftUI

// Clean

struct PlannerListView: View {
    @Binding var eventSheetContext: EventSheetContext?
    let plannerType: PlannerType
    let planner: Planner
    let plannerDay: DateInRegion
    let plannerLocation: Location?
    let sortedOpenPlannerEvents: [PlannerEvent]
    let sortedCheckedPlannerEvents: [PlannerEvent]
    let sortedPlannerEvents: [PlannerEvent]
    let plannerChipEvents: [EKEvent]
    let showChecked: Bool
    let namespace: Namespace.ID
    let scrollProxy: ScrollViewProxy
    let settings: PlannerSettings
    let createEvent: (UUID?, Int) -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var plannerManager: ListManager<PlannerEvent>
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    var body: some View {
        SortableListView(
            uncheckedItems: sortedOpenPlannerEvents,
            checkedItems: sortedCheckedPlannerEvents,
            showChecked: showChecked,
            checkedHeader: plannerType.checkedHeader,
            emptyUncheckedLabel: "No plans",
            emptyCheckedLabel: plannerType.emptyCheckedLabel,
            tint: eventTint,
            scrollProxy: scrollProxy,
            createItem: createEvent,
            moveItem: moveUncheckedEvent,
            floatingInfo: chipSpread,
            namespace: namespace,
            toolbarSystemImageNames: ["clock"],
            onToolbarTap: handleToolbarTap,
            toggleConfig: eventToggleConfig,
            leftAdornment: leftAdornment,
            rightAdornment: rightAdornment,
            bottomAdornment: bottomAdornment,
            handleTitleChange: handleEventTitleChange,
            checkedFooter: plannerType.checkedFooter(
                for: plannerDay
            )
        )
        .animateSynchronousAction(
            from: sortedOpenPlannerEvents.map(\.location?.name)
        )
        .task(id: planner.datestamp) {
            plannerManager.setToggleItem(toggleEvent)
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private var chipSpread: some View {
        PlannerChipSpreadView(
            planner: planner,
            plannerDay: plannerDay,
            sortedPlannerEvents: sortedPlannerEvents,
            plannerChipEvents: plannerChipEvents,
            namespace: namespace,
            settings: settings,
            plannerLocation: plannerLocation,
            openCalendarEventSheet: { calEvent in
                eventSheetContext =
                    EventSheetContext(
                        plannerEvent: nil,
                        calendarEvent: calEvent
                    )
            }
        )
    }

    @ViewBuilder
    private func leftAdornment(event: PlannerEvent) -> some View {
        if let calendarEvent = event.calendarEvent,
            let calendar = calendarEvent.calendar
        {
            Image(
                systemName:
                    calendar.systemImageName(settings: settings)
            )
            .foregroundStyle(calendar.color)
            .padding(.trailing, 6)
            .contentShape(Rectangle())
            .onTapGesture {
                openPlannerEventSheet(event)
            }
        }
    }

    @ViewBuilder
    private func rightAdornment(event: PlannerEvent) -> some View {
        event.timeValueView(
            in: plannerDay.region,
            accentColor: accentColor,
        ) {
            openPlannerEventSheet(event)
        }
    }

    @ViewBuilder
    private func bottomAdornment(event: PlannerEvent) -> some View {
        event.locationValueView(
            in: planner,
            settings: settings,
            deviceLocation: deviceLocationManager.deviceLocation,
            accentColor: accentColor
        ) {
            openPlannerEventSheet(event)
        }
    }

    // MARK: - Functions

    private func toggleEvent(_ event: PlannerEvent) {
        if event.isCanceled || plannerType == .future {
            event.isCanceled.toggle()
        } else {
            event.isCompleted.toggle()
        }
    }

    private func eventToggleConfig(_ event: PlannerEvent) -> ToggleConfig<
        PlannerEvent
    >? {
        let canceledIconConfig = IconConfig(
            name: "circle.slash",
            primaryColor: Color.red,
        )
        let deleteFromCalendarConfig = ConfirmationConfig<PlannerEvent>(
            title: "Delete from calendar?",
            message: "Hiding only affects visibility in this planner.",
            needsConfirmation: { event in
                event.calendarEvent != nil
                    && !event.isCanceled && plannerType == .future
            },
            actions: [
                ConfirmationAction(
                    title: "Hide",
                    role: nil
                ) { event in
                    modelContext.cancelPlannerEvent(event)
                },

                ConfirmationAction(
                    title: "Delete",
                    role: .destructive
                ) { event in
                    modelContext.deleteCalendarEvent(
                        event,
                        ekEventStore: calendarStore.ekEventStore
                    )
                },
            ]
        )

        if plannerType == .future || event.isCanceled {
            return ToggleConfig<PlannerEvent>(
                iconConfig: canceledIconConfig,
                confirmation: deleteFromCalendarConfig
            )
        }

        return nil
    }

    private func openPlannerEventSheet(_ event: PlannerEvent) {
        if plannerManager.isSelectMode || event.isChecked {
            plannerManager.toggleItem(event)
            return
        }

        plannerManager.protectedId = event.stableId
        plannerManager.focusedId = nil

        eventSheetContext =
            EventSheetContext(
                plannerEvent: event,
                calendarEvent: nil
            )
    }

    private func moveUncheckedEvent(from: Int, to: Int) {
        modelContext.movePlannerEvent(
            from: from,
            to: to,
            plannerDay: plannerDay,
            sortedEvents: sortedOpenPlannerEvents
        )
    }

    private func handleEventTitleChange(event: PlannerEvent) {
        modelContext.handlePlannerEventTitleChange(
            event,
            plannerDay: plannerDay,
            eventKitStore: calendarStore.ekEventStore,
            defaultLocation: plannerLocation
        )
    }

    private func handleToolbarTap(icon: String, event: PlannerEvent) {
        openPlannerEventSheet(event)
    }

    private func eventTint(event: PlannerEvent) -> Color {
        event.tint(accentColor: accentColor)
    }

}
