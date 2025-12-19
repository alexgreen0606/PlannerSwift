//
//  PlannerCard.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import SwiftDate
import SwiftUI
import EventKit
import WrappingHStack

struct PlannerCard: View {
    let datestamp: String
    let events: [EKEvent]

    var date: Date? {
        datestamp.toDate("yyyy-MM-dd", region: .current)?.date
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading) {
                Text(date?.longDate ?? datestamp)
                    .font(.headline)
                
                Text(date?.dayName ?? "")
                    .font(.subheadline)
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }

            PlannerChipSpreadView(datestamp: datestamp, events: events)
        }
    }
}

#Preview {
    PlannerCard(datestamp: "2025-12-10", events: [])
}
