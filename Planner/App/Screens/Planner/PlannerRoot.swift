//
//  PlannerRoot.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import EventKit
import EventKitUI
import SwiftData
import SwiftDate
import SwiftUI

struct PlannerRootView: View {
    private let planner: Planner
    private let sortedListItems: [PlannerItem]
    private let sortedChipItems: [PlannerItem]
    private let sortedBirthdayItems: [PlannerBirthdayItem]
    private let settings: Settings

    init(
        planner: Planner,
        sortedListItems: [PlannerItem],
        sortedChipItems: [PlannerItem],
        sortedBirthdayItems: [PlannerBirthdayItem],
        settings: Settings
    ) {
        self.planner = planner
        self.sortedListItems = sortedListItems
        self.sortedChipItems = sortedChipItems
        self.sortedBirthdayItems = sortedBirthdayItems
        self.settings = settings

        self._plannerEngine = StateObject(
            wrappedValue: ListEngine<PlannerItem>(
                toggleState: .completion(
                    modelContext: { [weak planner] in planner?.modelContext }
                ),
                settings: settings
            )
        )
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    @StateObject private var plannerEngine: ListEngine<PlannerItem>

    @State private var eventSheetContext: EventSheetContext?
    @State private var showTransferSheet = false
    @State private var showLocationSheet = false

    @Namespace private var namespace

    private var startOfDay: DateInRegion {
        planner.startOfDay(settings: settings)
    }

    private var sortedPendingListItems: [PlannerItem] {
        sortedListItems.filter(plannerEngine.isItemInPendingList)
    }

    private var sortedCompleteListItems: [PlannerItem] {
        sortedListItems.filter(plannerEngine.isItemInCompletedList)
    }

    private var visibleItems: [PlannerItem] {
        if planner.showCompleted {
            return sortedListItems + sortedChipItems
        }

        return sortedPendingListItems + sortedChipItems
    }

    private var plannerLocation: Location? {
        planner.location(
            settings: settings
        )
    }

    private var showHeaderDateIcon: Bool {
        planner.datestamp.isNext7Days(
            todaystamp: todayService.todaystamp
        )
    }

    // MARK: - Body

    var body: some View {
        ToastRootView(listEngine: plannerEngine) {
            NavigationStack {
                ScrollViewReader { scrollProxy in
                    PlannerContentsListView(
                        showLocationSheet: $showLocationSheet,
                        planner: planner,
                        startOfDay: startOfDay,
                        plannerLocation: plannerLocation,
                        sortedListItems: sortedListItems,
                        sortedPendingListItems: sortedPendingListItems,
                        sortedCompleteListItems: sortedCompleteListItems,
                        sortedChipItems: sortedChipItems,
                        sortedBirthdayItems: sortedBirthdayItems,
                        showCompleted: planner.showCompleted,
                        scrollProxy: scrollProxy,
                        settings: settings,
                        namespace: namespace,
                        createItem: createItem,
                        openItem: openItem
                    )
                    .safeAreaBar(edge: .bottom) {
                        actionToolbar(scrollProxy: scrollProxy)
                    }
                    .toolbar {
                        topLeadingToolbar
                        headerToolbar
                        topTrailingToolbar
                    }
                    .navigationBarTitleDisplayMode(.inline)
                }
            }

            // MARK: Transfer Events Form

            .sheet(isPresented: $showTransferSheet) {
                TransferEventsFormView(
                    sourceStartOfDay: startOfDay,
                    settings: settings
                )
                .navigationTransition(
                    .zoom(
                        sourceID: ListIds.TRANSFER_BUTTON,
                        in: namespace
                    )
                )
            }
            .environmentObject(plannerEngine)

            // MARK: Event Form

            .eventFormSheet(
                context: $eventSheetContext,
                planner: planner,
                settings: settings,
                namespace: namespace
            )
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var topLeadingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !plannerEngine.isSelectMode {
                BackButtonView(handleSideEffects: {
                    guard plannerCoverStore.showTodayDefault
                    else { return }

                    plannerEngine.blur()

                    withAnimation(.linear) {
                        plannerCoverStore.showTodayDefault = false
                    }
                })
            } else {
                CancelButtonView(cancel: plannerEngine.toggleSelectMode)
            }
        }
    }

    @ToolbarContentBuilder
    private var headerToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            PlannerHeaderView(
                datestamp: planner.datestamp,
                iconSize: 32,
                iconDetailSize: showHeaderDateIcon ? 9 : 11,
                iconDetailOffset: showHeaderDateIcon ? 3 : 18
            )
            .frame(
                width: plannerEngine.isSelectMode ? 162 : 242,
                alignment: .leading
            )
        }
        .sharedBackgroundVisibility(.hidden)
    }

    @ToolbarContentBuilder
    private var topTrailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !plannerEngine.isSelectMode {
                PlannerActionMenuView(
                    showLocationSheet: $showLocationSheet,
                    planner: planner,
                    plannerItems: sortedListItems,
                    hasVisibleEvents: !visibleItems.isEmpty
                )
            } else {
                SelectAllToggleView(visibleItems: visibleItems)
            }
        }
    }

    // MARK: - View Builders

    private func actionToolbar(scrollProxy: ScrollViewProxy) -> some View {
        var icons = ["info"]

        // Flagging is Planner-only data. Calendar events don't support it.
        if plannerEngine.activeEditor?.item.plannerEvent != nil {
            icons.append(
                plannerEngine.activeEditor?.draft.isFlagged == true
                    ? "flag.fill" : "flag"
            )
        }

        return ListActionToolbarView<
            PlannerItem,
            SelectedEventActionsView
        >(
            keyboardAccessory: ListKeyboardAccessoryView(
                iconImageNames: icons,
                onIconTap: handleToolbarTap
            ),
            selectedItemActions: SelectedEventActionsView(
                showTransferSheet: $showTransferSheet,
                planner: planner,
                namespace: namespace
            ),
            createItem: {
                createLowerItem(scrollProxy: scrollProxy)
            }
        )
    }

    // MARK: - Functions

    private func createItem(at index: Int) {
        plannerEngine.pendingFocusId = modelContext.createPlannerItem(
            at: index,
            in: sortedListItems,
            startOfDay: startOfDay
        )
    }

    private func handleToolbarTap(icon: String) {
        if let activeEditor = plannerEngine.activeEditor {
            switch icon {
            case "info":
                openItem(activeEditor.item)
            case "flag", "flag.fill":
                activeEditor.draft.isFlagged.toggle()
            default:
                break
            }
        }
    }

    private func createLowerItem(scrollProxy: ScrollViewProxy) {
        let targetIndex = getInsertionIndex(
            pendingIndex: sortedPendingListItems.count,
            sortedPendingItems: sortedPendingListItems,
            sortedItems: sortedListItems
        )

        createItem(at: targetIndex)
        scrollProxy.scrollToBottomOfList()
    }

    private func openItem(_ item: PlannerItem) {
        plannerEngine.openSheet(for: item) {
            eventSheetContext = EventSheetContext(
                item: item,
                planner: planner,
                ekEventStore: calendarService.ekEventStore,
                settings: settings
            )
        }
    }
}
