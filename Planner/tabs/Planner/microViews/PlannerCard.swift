//
//  PlannerCard.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import EventKit
import SwiftDate
import SwiftUI
import WrappingHStack

struct PlannerCard: View {
    let datestamp: String
    let events: [EKEvent]

    @State var navigationManager = NavigationManager.shared

    var date: Date? {
        datestamp.date
    }

    // TODO: next
    // 3. Add timed events below all-day spread and time values with them (match time colors with calendars too)

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        Text(date?.longDate ?? datestamp)
                            .font(.headline)

                        Spacer()

                        Text(date?.daysUntil ?? "")
                            .font(.caption)
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                    }

                    Text(date?.dayName ?? "")
                        .font(.subheadline)
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }

                PlannerChipSpreadView(
                    datestamp: datestamp,
                    events: events,
                    showCountdown: false
                )
            }

            Image(systemName: "chevron.right")
                .foregroundColor(Color(uiColor: .tertiaryLabel))
                .imageScale(.medium)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            navigationManager.plannerPath.append(datestamp)
        }
    }
}

#Preview {
    PlannerCard(datestamp: "2025-12-10", events: [])
}
