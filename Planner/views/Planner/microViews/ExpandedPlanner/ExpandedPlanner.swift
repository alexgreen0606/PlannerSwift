//
//  ExpandedPlanner.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct ExpandedPlannerView: View {
    let planner: Planner
    let plannerStartOfDay: DateInRegion
    let plannerLocation: Location?
    let sortedPlannerEvents: [PlannerEvent]
    let plannerChipEvents: [EKEvent]
    let settings: PlannerSettings

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampManager: TodaystampWatcher
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    @StateObject private var plannerManager = ListManager<PlannerEvent>()
    @State private var eventSheetContext: EventSheetContext?
    @State private var showTransferSheet = false

    @Namespace private var namespace

    // MARK: - Computed Variables

    private var plannerType: PlannerType {
        planner.datestamp <= todaystampManager.todaystamp
            ? .pastOrPresent : .future
    }

    private var showChecked: Bool {
        plannerType == .future ? planner.showCanceled : planner.showCompleted
    }

    private var visibleEvents: [PlannerEvent] {
        if showChecked {
            return sortedOpenPlannerEvents + sortedCheckedPlannerEvents
        }

        return sortedOpenPlannerEvents
    }

    private var isAllSelected: Bool {
        !visibleEvents.isEmpty &&
        plannerManager.selectedItemIds.count == visibleEvents.count
    }

    private var subtitle: String {
        if plannerManager.isSelectMode {
            let count = plannerManager.selectedItems.count
            return
                "\(count == 0 ? "No" : String(count)) plan\(count == 1 ? "" : "s") selected"
        }

        return plannerStartOfDay.dynamicSubheader
    }

    // MARK: Event Lists

    private var sortedOpenPlannerEvents: [PlannerEvent] {
        sortedPlannerEvents
            .filter {
                (!$0.isChecked
                    && !plannerManager.newlyUncheckedIds.contains($0.stableId))
                    || plannerManager.newlyCheckedIds.contains($0.stableId)
            }
    }

    private var sortedCheckedPlannerEvents: [PlannerEvent] {
        sortedPlannerEvents
            .filter {
                ($0.isChecked
                    && !plannerManager.newlyCheckedIds.contains($0.stableId))
                    || plannerManager.newlyUncheckedIds.contains($0.stableId)
            }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                PlannerListView(
                    eventSheetContext: $eventSheetContext,
                    plannerType: plannerType,
                    planner: planner,
                    plannerStartOfDay: plannerStartOfDay,
                    plannerLocation: plannerLocation,
                    sortedOpenPlannerEvents: sortedOpenPlannerEvents,
                    sortedCheckedPlannerEvents: sortedCheckedPlannerEvents,
                    sortedPlannerEvents: sortedPlannerEvents,
                    plannerChipEvents: plannerChipEvents,
                    showChecked: showChecked,
                    namespace: namespace,
                    scrollProxy: scrollProxy,
                    settings: settings,
                    createEvent: createEvent
                )
                .navigationTitle(plannerStartOfDay.dynamicHeader)
                .navigationSubtitle(subtitle)
                .toolbar {
                    upperLeftToolbar
                    upperRightToolbar
                    lowerToolbar(scrollProxy: scrollProxy)
                }
                .animateSynchronousAction(from: plannerManager.isSelectMode)
            }
        }

        // Event Sheet
        .sheet(item: $eventSheetContext) { context in
            EventFormView(
                sourcePlanner: planner,
                plannerEvent: context.plannerEvent,
                calendarEvent: context.calendarEvent,
                settings: settings,
            )
            .navigationTransition(
                .zoom(
                    sourceID: context.id,
                    in: namespace
                )
            )
            .onDisappear {
                plannerManager.protectedId = nil
            }
        }

        // Transfer Event Sheet
        .sheet(isPresented: $showTransferSheet) {
            TransferEventsFormView(
                startOfDay: plannerStartOfDay,
                settings: settings
            )
            .navigationTransition(
                .zoom(
                    sourceID: IdConstants.TRANSFER_BUTTON,
                    in: namespace
                )
            )
        }
        
        // Inject the manager last so it can be accessed in the sheets.
        .environmentObject(plannerManager)
    }

    // MARK: - Toolbars

    // MARK: Upper Left Toolbar

    @ToolbarContentBuilder
    private var upperLeftToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if !plannerManager.isSelectMode {
                backButton
            } else {
                cancelSelectModeButton
            }
        }
    }

    private var backButton: some View {
        Button("Back", systemImage: "chevron.left") {
            dismiss()
        }
    }

    private var cancelSelectModeButton: some View {
        Button(
            "Cancel Select Mode",
            systemImage: "xmark",
            action: plannerManager.toggleSelectMode
        )
        // Note: This fixes a bug where opening select mode while a keyboard is open causes this button to
        // appear tinted as the accent color.
        .tint(Color.label)
    }

    // MARK: Upper Right Toolbar

    @ToolbarContentBuilder
    private var upperRightToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !plannerManager.isSelectMode {
                PlannerActionMenuView(
                    plannerType: plannerType,
                    planner: planner,
                    showChecked: showChecked,
                    plannerEvents: sortedPlannerEvents,
                    visibleEvents: visibleEvents
                )
            } else {
                selectAllToggle
            }
        }
    }

    private var selectAllToggle: some View {
        Button {
            plannerManager.toggleSelectAll(visibleItems: visibleEvents)
        } label: {
            Text(isAllSelected ? "Deselect All" : "Select All")
                .fontWeight(.semibold)
        }
        .disabled(visibleEvents.isEmpty)
    }

    // MARK: Lower Toolbar

    @ToolbarContentBuilder
    private func lowerToolbar(scrollProxy: ScrollViewProxy)
        -> some ToolbarContent
    {
        ToolbarItemGroup(placement: .bottomBar) {
            if !plannerManager.isSelectMode {
                Spacer()
                createLowerEventButton(scrollProxy: scrollProxy)
            } else {
                SelectedEventActionsView(
                    showTransferSheet: $showTransferSheet,
                    settings: settings,
                    namespace: namespace
                )
            }
        }
    }

    private func createLowerEventButton(scrollProxy: ScrollViewProxy)
        -> some View
    {
        Button("Add", systemImage: "plus") {
            createLowerEvent(scrollProxy: scrollProxy)
        }
        .tint(accentColor.color)
    }

    // MARK: - Functions

    private func createEvent(
        near baseId: UUID?,
        offset: Int = 0
    ) {
        plannerManager.pendingFocusId = modelContext.createStorageEvent(
            in: sortedOpenPlannerEvents,
            near: baseId,
            offset: offset,
            startOfDay: plannerStartOfDay,
            settings: settings
        )
    }

    private func createLowerEvent(scrollProxy: ScrollViewProxy) {
        createEvent(
            near: sortedOpenPlannerEvents.last?.stableId,
            offset: 1
        )
        scrollToBottom(scrollProxy: scrollProxy)
    }

    private func scrollToBottom(scrollProxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation {
                scrollProxy.scrollTo(
                    IdConstants.UNCHECKED_ITEMS,
                    anchor: .bottom
                )
            }
        }
    }

}
