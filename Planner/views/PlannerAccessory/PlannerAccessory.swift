//
//  PlannerAccessory.swift
//  Planner
//
//  Created by Alex Green on 12/21/25.
//

import EventKit
import SwiftUI

struct PlannerAccessoryView: View {
    @Binding var isPlannerOpen: Bool
    var animation: Namespace.ID
    
    @EnvironmentObject var todaystampManager: TodaystampManager
    @State var navigationManager = NavigationManager.shared
    @EnvironmentObject var calendarEventStore: CalendarEventStore
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    private var eventsForToday: [EKEvent] {
        return calendarEventStore.allDayEventsByDatestamp[
            todaystampManager.todaystamp
        ] ?? []
    }

    var body: some View {
        HStack(spacing: 6) {
            PlannerIcon()

            VStack(alignment: .leading, spacing: 0) {
                Text(todaystampManager.todaystamp.date?.dayName ?? "")
                    .font(.callout)
                    .matchedTransitionSource(
                        id: "ACCESSORY",
                        in: animation
                    )

                HStack(alignment: .center, spacing: 6) {
                    if !eventsForToday.isEmpty {
                        HStack(alignment: .bottom, spacing: 2) {
                            ForEach(eventsForToday, id: \.self) { event in
                                Image(systemName: event.calendar.iconName)
                                    .font(.caption)
                                    .imageScale(.small)
                                    .foregroundStyle(
                                        Color(event.calendar.cgColor)
                                    )
                            }
                        }
                        
                        Divider().frame(height: 10)
                    }

                    Text("7 plans")
                        .font(.caption2)
                        .foregroundStyle(
                            Color(uiColor: .secondaryLabel)
                        )
                }
            }
            .lineLimit(1)

            Spacer()

            HStack(alignment: .center) {
                if placement != .inline {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Sunny")
                            .font(.caption)
                        
                        HStack(alignment: .center, spacing: 4) {
                            Text("76°")
                                .font(.caption2)
                            
                            Divider().frame(height: 10)
                            
                            Text("64°")
                                .font(.caption2)
                        }
                        .foregroundStyle(
                            Color(uiColor: .secondaryLabel)
                        )
                    }
                }

                Image(systemName: "sun.max.fill")
                    .imageScale(.medium)
                    .foregroundStyle(.yellow)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            navigationManager.plannerDatestamp =
                todaystampManager.todaystamp
            isPlannerOpen.toggle()
        }
    }
}

#Preview {
    ContentView()
}
