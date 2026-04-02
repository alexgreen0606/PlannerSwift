//
//  TripView.swift
//  Planner
//
//  Created by Alex Green on 3/22/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct TripView: View {
    @Binding var expandedTrips: Set<PersistentIdentifier>
    let trip: Trip
    let namespace: Namespace.ID
    let settings: PlannerSettings
    let scrollToTrip: () -> Void
    let openTripForm: () -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.displayScale) private var displayScale
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher

    private var isExpanded: Bool {
        expandedTrips.contains(trip.id)
    }

    private var firstDay: DateInRegion? {
        guard let firstDayPlanner = trip.sortedPlanners.first else {
            return nil
        }
        return firstDayPlanner.datestamp.startOfDay(
            in: firstDayPlanner.region(settings: settings)
        )
    }

    private var lastDay: DateInRegion? {
        guard let lastDayPlanner = trip.sortedPlanners.last else {
            return nil
        }
        return lastDayPlanner.datestamp.startOfDay(
            in: lastDayPlanner.region(settings: settings)
        )
    }

    private var locationLabel: String? {
        trip.location?.name
    }

    private var todaystamp: String {
        todaystampWatcher.todaystamp
    }

    private var datesLabel: String {
        trip.dateRangeLabel ?? ""
    }

    private var countdownLabel: String {
        guard let firstDay, let lastDay else {
            return ""
        }

        if firstDay.datestamp <= todaystamp, lastDay.datestamp >= todaystamp {
            return ""
        }

        return firstDay.countdown
    }

    var body: some View {
        VStack {
            header
            if isExpanded {
                previewSpread
            }
        }
        .id("\(trip.id)_\(String(isExpanded))")
        .discreetListItem()
    }

    // MARK: - View Builders

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(trip.title)
                    .font(
                        .system(size: 20, weight: .heavy, design: .rounded)
                    )

                if let locationLabel {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 10, height: 10)
                            .foregroundStyle(accentColor.color, Color.secondary)

                        Text(locationLabel)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(datesLabel)
                    .font(.system(size: 14, weight: .bold, design: .rounded))

                Text(countdownLabel)
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                if isExpanded {
                    expandedTrips.remove(trip.id)
                } else {
                    expandedTrips.insert(trip.id)
                    scrollToTrip()
                }
            }
        }
    }

    @ViewBuilder
    private var previewSpread: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(
                    Array(trip.sortedPlanners.enumerated()),
                    id: \.element
                ) { index, planner in
                    PlannerEventBuilderView(
                        planner: planner,
                        settings: settings,
                        previewType: .trip,
                        header: {
                            PlannerHeaderView(
                                day: $0,
                                title: "Day \(index + 1)",
                                subtitle: $0.weekday,
                                iconFormat: .shortMonth
                            )
                        },
                        namespace: namespace,
                        transitionSource: trip.transitionId(
                            for: planner.datestamp
                        )
                    )
                }

                editTripCard
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear)
    }

    private var editTripCard: some View {
        HStack {
            Image(systemName: "pencil")
            Text("Edit Trip")
        }
        .foregroundStyle(accentColor.color)
        .font(.system(size: 14, weight: .bold, design: .rounded))
        .frame(
            width: 240,
            height: PlannerLayout.PREVIEW_CARD_HEIGHT,
            alignment: .center
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    accentColor.color,
                    style: StrokeStyle(
                        lineWidth: 1,
                        dash: [6]
                    )
                )
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: openTripForm)
        .matchedTransitionSource(
            id: trip.id,
            in: namespace
        )
    }

}
