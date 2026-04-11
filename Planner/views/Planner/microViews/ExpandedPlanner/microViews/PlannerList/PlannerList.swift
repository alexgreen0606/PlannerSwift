//
//  PlannerList.swift
//  Planner
//
//  Created by Alex Green on 3/11/26.
//

import EventKit
import SwiftDate
import SwiftUI
import SwiftData
import WeatherKit

// Clean

struct PlannerListView: View {
    @Binding var showLocationSheet: Bool
    @Binding var eventSheetContext: EventSheetContext?
    let plannerType: PlannerType
    let planner: Planner
    let plannerDay: DateInRegion
    let plannerLocation: Location?
    let sortedOpenPlannerEvents: [PlannerEvent]
    let sortedCheckedPlannerEvents: [PlannerEvent]
    let sortedPlannerEvents: [PlannerEvent]
    let calendarDayData: CalendarDayData
    let showChecked: Bool
    let namespace: Namespace.ID
    let scrollProxy: ScrollViewProxy
    let settings: PlannerSettings
    let createEvent: (Int) -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue
    
    @AppStorage("keepCanceledEventsDuration") private
        var keepCanceledEventsDuration: KeepCanceledEventsDuration =
            KeepCanceledEventsDuration.startOfDay

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var plannerManager: ListManager<PlannerEvent>
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var weatherStore: WeatherStore
    
    private var weatherData: DayWeather? {
        weatherStore.getWeather(for: plannerDay, at: plannerLocation)
    }
    
    private var locationLabel: String {
        planner.locationLabel(
            settings: settings,
            deviceLocation: deviceLocationManager.deviceLocation
        )
    }

    var body: some View {
        SortableListView(
            uncheckedItems: sortedOpenPlannerEvents,
            checkedItems: sortedCheckedPlannerEvents,
            rowId: eventId,
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
            toolbarSystemImageNames: ["rectangle.and.pencil.and.ellipsis"],
            onToolbarTap: handleToolbarTap,
            toggleConfig: eventToggleConfig,
            leftAdornment: leftAdornment,
            rightAdornment: rightAdornment,
            bottomAdornment: bottomAdornment,
            handleTitleChange: handleEventTitleChange,
            checkedFooter: plannerType.checkedFooter(
                for: planner.datestamp,
                todaystamp: todaystampWatcher.todaystamp,
                keepCanceledEvents: keepCanceledEventsDuration
            )
        )
        .task(id: planner.datestamp) {
            plannerManager.setToggleItem(toggleEvent)
        }
        .animateAsynchronousAction(from: weatherData)
        .animateAsynchronousAction(from: locationLabel)
        .animateAsynchronousAction(
            from: calendarDayData.plannerChipEvents.map(\.title)
        )
    }

    // MARK: - View Builders

    @ViewBuilder
    private var chipSpread: some View {
        PlannerChipSpreadView(
            showLocationSheet: $showLocationSheet,
            planner: planner,
            plannerDay: plannerDay,
            weatherData: weatherData,
            locationLabel: locationLabel,
            calendarDayData: calendarDayData,
            sortedPlannerEvents: sortedPlannerEvents,
            namespace: namespace,
            settings: settings,
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
        event.timeAdornment(
            in: plannerDay.region,
            accentColor: accentColor,
        ) {
            openPlannerEventSheet(event)
        }
    }

    @ViewBuilder
    private func bottomAdornment(event: PlannerEvent) -> some View {
        event.locationAdornment(
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

        // If an event is canceled, reset its entire checked state.
        if event.isCanceled {
            event.isCanceled = false
            event.isCompleted = false
            return
        }

        // If this is a future event, cancel it and clear the completed state.
        if plannerType == .future {
            event.isCanceled = true
            event.isCompleted = false
            return
        }

        // Otherwise just toggle the completed state.
        event.isCompleted.toggle()
    }

    private func eventToggleConfig(_ event: PlannerEvent) -> ToggleConfig<
        PlannerEvent
    >? {
        ToggleConfig<PlannerEvent>(
            iconConfig: IconConfig(
                name: event.isCanceled ? "circle.slash" : "circle.inset.filled",
                primaryColor: event.isCanceled
                    ? Color.red : event.tint(accentColor: accentColor),
            ),
            confirmation: ConfirmationConfig<PlannerEvent>(
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
        )
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

    private func eventId(event: PlannerEvent) -> String {
        "\(event.stableId)_\(event.location?.name ?? "NO_LOCATION")"
    }

}
