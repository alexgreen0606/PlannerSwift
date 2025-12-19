//
//  PlannerSelector.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import SwiftDate
import SwiftUI

struct PlannerSelectView: View {
    @EnvironmentObject var todaystampManager: TodaystampManager
    @EnvironmentObject var calendarStore: CalendarEventStore

    let plannerManager = ListManager()

    @State private var isCalendarPickerOpen = false
    @State var navigationManager = NavigationManager.shared

    var body: some View {
        List {
            Section {
                DatePicker(
                    "Open a planner",
                    selection: $navigationManager
                        .selectedPlannerDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .onChange(of: navigationManager.selectedPlannerDate) {
                    _,
                    newDate in
                    let newStamp = newDate.toFormat("yyyy-MM-dd")
                    if newStamp == todaystampManager.todaystamp {
                        // Clear the navigation stack when going back to today's planner.
                        navigationManager.plannerPath =
                            NavigationPath()
                    } else {
                        navigationManager.plannerPath.append(
                            newStamp
                        )
                    }
                }
            }

            Section {
                let sortedDates = calendarStore.allDayEventsByDatestamp.keys.sorted()
                ForEach(sortedDates, id: \.self) { datestamp in
                    let events = calendarStore.allDayEventsByDatestamp[datestamp] ?? []
                    PlannerCard(datestamp: datestamp, events: events)
                }

            } header: {
                Text("Upcoming dates")
            } footer : {
                Text("All later dates can be accessed in the calendar above.")
            }

        }
        .navigationTitle("Planner")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
    }
}

#Preview {
    PlannerTabView()
}
