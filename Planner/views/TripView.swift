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

    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher

    private var isExpanded: Bool {
        expandedTrips.contains(trip.id)
    }

    private var startDay: DateInRegion? {
        DateInRegion(trip.startDatestamp, region: .local)
    }

    private var endDay: DateInRegion? {
        DateInRegion(trip.endDatestamp, region: .local)
    }

    private var locationLabel: String? {
        trip.location?.name
    }

    private var todaystamp: String {
        todaystampWatcher.todaystamp
    }

    private var datesLabel: String {
        guard let startDay, let endDay else {
            return ""
        }

        if trip.startDatestamp == trip.endDatestamp {
            return startDay.tripLabel
        }

        return "\(startDay.tripLabel) - \(endDay.tripLabel)"
    }

    private var countdownLabel: String {
        if trip.startDatestamp <= todaystamp, trip.endDatestamp >= todaystamp {
            return ""
        }
        return startDay?.countdown ?? ""
    }

    var body: some View {
        VStack {
            header
            if isExpanded {
                previewSpread
            }
        }
        .id("\(trip.id)_\(String(isExpanded))")
    }

    // MARK: - View Builders

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text(trip.title)
                    .font(
                        .system(size: 18, weight: .heavy, design: .rounded)
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

            Image(systemName: "chevron.right")
                .frame(width: 24)
                .frame(maxHeight: .infinity)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .animation(.linear, value: isExpanded)
                .foregroundStyle(Color.secondary)

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
        .matchedTransitionSource(
            id: String(describing: trip.id),
            in: namespace
        )
    }

    @ViewBuilder
    private var previewSpread: some View {
        VStack(alignment: .leading) {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(
                        Array(trip.sortedDatestamps.enumerated()),
                        id: \.element
                    ) { index, datestamp in
                        PlannerBuilderView(
                            datestamp: datestamp,
                            settings: settings,
                            previewType: .trip,
                            customTitle: "Day \(index + 1)",
                            namespace: namespace,
                            transitionSource: trip.plannerTransitionId(
                                for: datestamp
                            )
                        )
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
            .background(Color.clear)

            ActionButtonView(
                label: "Edit \(trip.title) Trip",
                systemImage: "pencil",
                onTap: openTripForm
            )
            .tint(accentColor.color)
            .padding()
        }
    }
}
