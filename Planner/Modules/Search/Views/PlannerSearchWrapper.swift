//
//  PlannerSearchWrapper.swift
//  Planner
//
//  Created by Alex Green on 11/16/26.
//

import SwiftUI

// Note: Ensure this is placed within a NavigationStack

struct PlannerSearchWrapperView<Content: View>: View {
    var isSearchFocused: FocusState<Bool>.Binding
    let settings: Settings
    let content: () -> Content

    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var plannerService: PlannerService

    @State private var searchTask: Task<Void, Never>?

    private var activeQuery: PlannerSearchQuery? {
        plannerService.activeQuery
    }

    // MARK: - Body

    var body: some View {
        content()
            .safeAreaBar(edge: .bottom) {
                searchBar
            }
            .toolbar {
                if activeQuery?.filterCount != nil
                    || activeQuery?.isSearchingText == true
                {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Reset") {
                            plannerService.draftQuery = PlannerSearchQuery(
                                text: "",
                                calendarIds: []
                            )

                            withAnimation {
                                search()
                            }
                        }
                    }
                }

                ToolbarSpacer(.fixed, placement: .topBarTrailing)

                PlannerFilterToolbarView(
                    draftQuery: $plannerService.draftQuery,
                    filterCount: activeQuery?.filterCount,
                    settings: settings
                )

                ToolbarItem(placement: .topBarTrailing) {
                    Button("", systemImage: "magnifyingglass") {
                        isSearchFocused.wrappedValue.toggle()
                    }
                    .badge(
                        activeQuery?.isSearchingText == true ? "1" : nil
                    )
                }
            }

            // MARK: Schedule a search each time the draft query changes.

            .onChange(of: plannerService.draftQuery) { _, _ in
                scheduleSearch()
            }
    }

    // MARK: - View Helpers

    @ViewBuilder
    private var searchBar: some View {
        HStack {
            SearchBarView(
                text: $plannerService.draftQuery.text,
                isFocused: isSearchFocused,
                placeholder: "Search planner..."
            )

            GlassIconButtonView(
                systemImageName: "xmark",
                onTap: {
                    plannerService.draftQuery.text = ""
                    isSearchFocused.wrappedValue = false
                }
            )
        }
        .opacity(isSearchFocused.wrappedValue ? 1 : 0)
        .padding(
            EdgeInsets(
                top: 16,
                leading: 16,
                bottom: 8,
                trailing: 16
            )
        )
    }

    // MARK: - Functions

    private func search() {
        plannerService.loadPlannerList()
    }

    private func scheduleSearch() {
        searchTask?.cancel()

        searchTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(850))
                guard !Task.isCancelled else { return }

                search()
            } catch {}
        }
    }
}
