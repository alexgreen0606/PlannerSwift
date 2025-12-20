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

    let plannerManager = ListManager()

    @State private var isCalendarPickerOpen = false
    @State var navigationManager = NavigationManager.shared
    @State var calendarEventStore = CalendarEventStore.shared

    @AppStorage("themeColor") private var themeColor: ThemeColorOption = .blue

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
                .listRowBackground(Color.clear)
                .onChange(of: navigationManager.selectedPlannerDate) {
                    _,
                    targetPlannerDate in
                    navigationManager.plannerPath.append(
                        targetPlannerDate.datestamp
                    )
                }
            }

            Section {
                let sortedDates = calendarEventStore.allDayEventsByDatestamp.keys
                    .sorted()
                ForEach(sortedDates, id: \.self) { datestamp in
                    let events =
                    calendarEventStore.allDayEventsByDatestamp[datestamp] ?? []
                    PlannerCard(datestamp: datestamp, events: events)
                }
            } header: {
                Text("Upcoming dates")
            } footer: {
                Text("All later dates can be accessed in the calendar above.")
            }

        }
        .navigationTitle("Planner")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Menu {
                        ForEach(ThemeColorOption.allCases, id: \.self) { option in
                            Button {
                                themeColor = option
                            } label: {
                                Label {
                                    Text(option.label)
                                } icon: {
                                    Image(systemName:
                                        themeColor == option
                                        ? "circle.fill"
                                        : "circle"
                                    )
                                }
                                .tint(option.swiftUIColor)
                            }
                        }
                    } label: {
                        Label("Theme Color", systemImage: "paintpalette.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }

    }
}

#Preview {
    PlannerTabView()
}
