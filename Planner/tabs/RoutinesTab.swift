//
//  RoutinesTab.swift
//  Planner
//
//  Created by Alex Green on 3/30/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct RoutineCoverContext: Identifiable {
    var dayOfWeek: DayOfWeek

    var id: String {
        dayOfWeek.rawValue
    }

}

struct RoutinesTabView: View {

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @State private var routineCoverContext: RoutineCoverContext? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    weekdaysCard

                    ForEach(
                        DayOfWeek.allCases,
                        id: \.self,
                        content: dayOfWeekCard
                    )
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color.appBackground)
            .navigationTitle("Routines")
            .navigationBarTitleDisplayMode(.inline)

            // Day Routines Sheet
            .fullScreenCover(item: $routineCoverContext) { context in
                // Routine List
            }
        }
    }

    // MARK: - View Builders

    private var weekdaysCard: some View {
        VStack(alignment: .leading) {
            Text("Weekdays")
                .font(
                    .system(size: 22, weight: .bold, design: .rounded)
                )
                .padding()
            Spacer()
            HStack {
                ForEach(DayOfWeek.allCases, id: \.self) { d in
                    Text(d.initial)
                        .foregroundStyle(
                            [DayOfWeek.saturday, DayOfWeek.sunday].contains(d)
                                ? Color.tertiary : accentColor.color
                        )
                        .font(
                            .system(size: 14, weight: .black, design: .rounded)
                        )
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardBackground)
        )
        .overlay {
            EmptyLabelView(text: "No routines")
        }
        .padding(.bottom)
    }

    private func dayOfWeekCard(_ dayOfWeek: DayOfWeek) -> some View {
        VStack(alignment: .leading) {
            Text(dayOfWeek.rawValue.capitalizedFirst)
                .font(
                    .system(size: 22, weight: .bold, design: .rounded)
                )
                .padding()
            Spacer()
            HStack {
                ForEach(DayOfWeek.allCases, id: \.self) { d in
                    Text(d.initial)
                        .foregroundStyle(
                            d == dayOfWeek ? accentColor.color : Color.tertiary
                        )
                        .font(
                            .system(size: 14, weight: .black, design: .rounded)
                        )
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardBackground)
        )
        .overlay {
            EmptyLabelView(text: "No routines")
        }
    }

}
