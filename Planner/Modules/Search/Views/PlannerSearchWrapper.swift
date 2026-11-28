//
//  PlannerSearchWrapper.swift
//  Planner
//
//  Created by Alex Green on 11/16/26.
//

import SwiftUI

// Note: Ensure this is placed within a NavigationStack.
// Note: Add `PlannerSearchToolbarContent` to the toolbar for the filter, search, and reset buttons.

struct PlannerSearchWrapperView<Content: View>: View {
    var isSearchFocused: FocusState<Bool>.Binding
    let settings: Settings
    let content: () -> Content

    @EnvironmentObject private var plannerService: PlannerService

    @State private var searchTask: Task<Void, Never>?

    // MARK: - Body

    var body: some View {
        content()
            .safeAreaBar(edge: .bottom) {
                searchBar
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
