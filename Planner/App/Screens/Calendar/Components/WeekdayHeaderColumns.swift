//
//  WeekdayHeaderColumns.swift
//  Planner
//
//  Created by Alex Green on 11/16/26.
//

import SwiftDate
import SwiftUI

struct WeekdayHeaderColumnsView: View {
    let columns: [GridItem]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(Weekday.allCases, id: \.self) { weekday in
                    Text(weekday.initial)
                        .font(
                            .system(
                                size: 14,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical)
        }
    }
}
