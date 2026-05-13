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
    let openEditSheet: () -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.displayScale) private var displayScale
    @EnvironmentObject private var TodaystampService: TodaystampService
    @EnvironmentObject private var PlannerCoverStore: PlannerCoverStore

    private var isExpanded: Bool {
        expandedTrips.contains(trip.id)
    }

    private var firstDatestamp: String? {
        trip.firstDatestamp
    }

    private var lastDatestamp: String? {
        trip.lastDatestamp
    }

    private var locationLabel: String? {
        trip.location?.name
    }

    private var todaystamp: String {
        TodaystampService.todaystamp
    }

    private var datesLabel: String {
        trip.dateRangeLabel(todaystamp: TodaystampService.todaystamp)
    }

    private var countdownLabel: String {
        guard let firstDatestamp, let lastDatestamp else {
            return ""
        }

        if firstDatestamp <= todaystamp, lastDatestamp >= todaystamp {
            return ""
        }

        return firstDatestamp.countdown(
            todaystamp: TodaystampService.todaystamp
        )
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

                if countdownLabel.count == 0 {
                    progressBar
                } else {
                    Text(countdownLabel)
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                }
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
                    TripDayPreviewCardView(
                        datestamp: planner.datestamp,
                        index: index,
                        trip: trip,
                        settings: settings,
                        namespace: namespace
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

    private var progressBar: some View {
        trip.progressBar(
            day: trip.day(of: todaystamp),
            accentColor: accentColor
        )
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
        .onTapGesture(perform: openEditSheet)
        .matchedTransitionSource(
            id: "\(trip.id)",
            in: namespace
        )
    }

}
