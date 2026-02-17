//
//  CalendarsForm.swift
//  Planner
//
//  Created by Alex Green on 1/22/26.
//

import Combine
import EventKit
import SwiftData
import SwiftUI

struct CalendarsFormView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    
    @Query private var calendarSettingsList: [CalendarSettings]

    @State private var calendarRefreshDebounce: Task<Void, Never>?

    private var calendarSettings: CalendarSettings? {
        calendarSettingsList.first
    }

    private var iconOptions: [String] = [
        "briefcase.fill",
        "airplane",
        "suitcase.fill",
        "popcorn",
        "globe.americas.fill",
        "birthday.cake.fill",
        "calendar",
        "dollarsign",
        "mountain.2.fill",
        "dog.fill",
        "basketball.fill",
    ]

    var body: some View {
        List {
            ForEach(
                calendarStore.sortedCalendars,
                id: \.calendarIdentifier
            ) { calendar in
                HStack {
                    Image(
                        systemName: calendarSettings?.hiddenCalendarIds
                            .contains(calendar.calendarIdentifier)
                        == false
                        ? "checkmark.circle" : "circle"
                    )
                    .foregroundStyle(Color(calendar.cgColor))
                    .contentShape(Rectangle())
                    .contentTransition(
                        .symbolEffect(
                            .replace.magic(fallback: .replace)
                        )
                    )
                    .onTapGesture {
                        guard let calendarSettings else { return }
                        
                        if calendarSettings.hiddenCalendarIds.contains(
                            calendar.calendarIdentifier
                        ) {
                            calendarSettings.hiddenCalendarIds.remove(
                                calendar.calendarIdentifier
                            )
                        } else {
                            calendarSettings.hiddenCalendarIds.insert(
                                calendar.calendarIdentifier
                            )
                        }
                        
                        try! modelContext.save()
                    }
                    
                    Text(calendar.title)
                    
                    Spacer()
                    
                    Menu {
                        ForEach(iconOptions, id: \.self) { iconName in
                            Button("", systemImage: iconName) {
                                guard let calendarSettings else {
                                    return
                                }
                                
                                calendarSettings.iconMap[
                                    calendar.calendarIdentifier
                                ] = iconName
                                
                                try! modelContext.save()
                            }
                        }
                    } label: {
                        Image(
                            systemName: calendarSettings?.iconMap[
                                calendar.calendarIdentifier
                            ] ?? calendar.iconName
                        )
                        .foregroundStyle(Color(calendar.cgColor))
                    }
                }
            }
        }
        .navigationTitle("Calendars")
        .navigationBarTitleDisplayMode(.inline)
        
        // Refresh the calendar when the hidden calendars change.
        .onChange(of: calendarSettings?.hiddenCalendarIds) { _, _ in
            scheduleCalendarRefreshDebounce()
        }
    }

    private func scheduleCalendarRefreshDebounce() {
        calendarRefreshDebounce?.cancel()

        calendarRefreshDebounce = Task {
            do {
                try await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }

                // Refresh the calendar data.
                calendarStore.loadFreshCache(
                    hiddenCalendarIds: calendarSettings?.hiddenCalendarIds ?? []
                )
            } catch {
            }
        }
    }

}
