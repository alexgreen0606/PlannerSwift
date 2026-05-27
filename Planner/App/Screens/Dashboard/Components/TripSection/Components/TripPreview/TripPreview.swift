//
//  TripPreview.swift
//  Planner
//
//  Created by Alex Green on 3/22/26.
//

import SwiftData
import SwiftUI

struct TripPreviewView: View {
    @Binding var expandedTripIds: Set<PersistentIdentifier>
    let trip: Trip
    let settings: PlannerSettings
    let namespace: Namespace.ID
    let openEditSheet: () -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var todayService: TodayService

    private var isExpanded: Bool {
        expandedTripIds.contains(trip.id)
    }

    private var locationLabel: String? {
        trip.location?.name
    }

    private var dateRangeLabel: String {
        trip.dateRangeLabel(todaystamp: todayService.todaystamp)
    }

    private var countdownLabel: String {
        if trip.firstDatestamp <= todayService.todaystamp,
           trip.lastDatestamp >= todayService.todaystamp
        {
            return ""
        }

        return trip.firstDatestamp.countdown(
            todaystamp: todayService.todaystamp
        )
    }

    // MARK: - Body

    var body: some View {
        VStack {
            header
            if isExpanded {
                dayPreviews
            }
        }
        .id(getTripRenderId(tripId: trip.id, isExpanded: isExpanded))
        .discreetListItem()
    }

    // MARK: - View Builders

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.title)
                    .font(
                        .system(size: 20, weight: .heavy, design: .rounded)
                    )

                if let locationLabel {
                    AdornedValue(
                        locationLabel,
                        iconConfig: IconConfig(
                            name: "mappin.and.ellipse",
                            primaryColor: accentColor.color
                        ),
                        color: Color.secondary,
                        scale: 0.8
                    )
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(dateRangeLabel)
                    .font(.system(size: 14, weight: .bold, design: .rounded))

                if countdownLabel.isEmpty {
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
            if isExpanded {
                expandedTripIds.remove(trip.id)
            } else {
                expandedTripIds.insert(trip.id)
            }
        }
    }

    private var progressBar: some View {
        trip.progressBar(
            day: trip.day(of: todayService.todaystamp),
            accentColor: accentColor
        )
    }

    // MARK: - Day Previews

    private var dayPreviews: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(
                    Array(trip.sortedPlanners.enumerated()),
                    id: \.element.datestamp
                ) { index, planner in
                    TripDayPreviewCardView(
                        trip: trip,
                        datestamp: planner.datestamp,
                        index: index,
                        settings: settings,
                        namespace: namespace
                    )
                }

                editTripCard
            }
            .padding([.horizontal, .bottom])
        }
        .background(Color.clear)
        .scrollIndicators(.hidden)
    }

    private var editTripCard: some View {
        HStack {
            Image(systemName: "pencil")
            Text("Edit Trip")
        }
        .font(.system(size: 14, weight: .bold, design: .rounded))
        .foregroundStyle(accentColor.color)
        .frame(
            width: PlannerPreviewCardLayout.DEFAULT_WIDTH,
            height: PlannerPreviewCardLayout.HEIGHT
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: PlannerPreviewCardLayout.CORNER_RADIUS
            )
            .stroke(
                accentColor.color,
                style: StrokeStyle(
                    lineWidth: 1,
                    dash: [6]
                )
            )
        )
        .matchedTransitionSource(
            id: trip.transitionId,
            in: namespace
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: openEditSheet)
    }
}
