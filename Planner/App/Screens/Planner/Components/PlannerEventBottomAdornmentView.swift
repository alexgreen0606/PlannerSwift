//
//  PlannerEventBottomAdornmentView.swift
//  Planner
//
//  Created by Alex Green on 2/27/26.
//

import SwiftDate
import SwiftUI

struct PlannerEventBottomAdornmentView: View {
    let plannerEvent: PlannerEvent
    let planner: Planner
    let settings: Settings
    let handleEventClick: () -> Void

    private let CURRENT_ID = "CURRENT"
    private let SCALE: CGFloat = 0.65

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var todayService: TodayService

    private var eventDatestamp: String {
        if let time = plannerEvent.time {
            // Timed event: placed in a day from the perspective of the planner.
            return DatestampFormatter.datestamp(
                from: time,
                timeZone: plannerRegion.timeZone
            )
        } else if let datestamp = plannerEvent.datestamp {
            // Untimed event: placed directly in its parent planner.
            return datestamp
        } else {
            // Fallback that should never occur in theory.
            return planner.datestamp
        }
    }

    private var plannerRegion: Region {
        planner.region(settings: settings)
    }

    private var plannerTimeZoneId: String {
        plannerRegion.timeZone.identifier
    }

    private var locationContextsByTimeZoneSecondsFromGmt:
        [Int: [LocationContext]]
    {
        let typedLocations: [TypedLocation] = [
            TypedLocation(location: plannerEvent.location, type: .event),
            TypedLocation(location: settings.homeLocation, type: .home),
            TypedLocation(location: planner.trip?.location, type: .trip),
        ]

        var contextMap: [Int: [String: LocationContext]] = [:]

        let currentTimeZoneSecondsFromGmt = TimeZone.current.secondsFromGMT()
        let shouldDisplayCurrent = LocationType.current.shouldDisplayLocation(
            for: plannerEvent,
            planner: planner,
            locationTimeZoneId: TimeZone.current.identifier,
            settings: settings
        )
        var didAddCurrent = false

        for typedLocation in typedLocations {
            guard
                let location = typedLocation.location,
                typedLocation.type.shouldDisplayLocation(
                    for: plannerEvent,
                    planner: planner,
                    locationTimeZoneId: location.timeZoneIdentifier,
                    settings: settings
                ),
                let secondsFromGmt = TimeZone(
                    identifier: location.timeZoneIdentifier
                )?.secondsFromGMT()
            else {
                continue
            }

            var context =
                contextMap[secondsFromGmt, default: [:]][
                    location.coordinateId
                ] ?? LocationContext(location: location)

            context.types.append(typedLocation.type)

            if shouldDisplayCurrent,
                !didAddCurrent,
                secondsFromGmt == currentTimeZoneSecondsFromGmt,
                context.location?.name
                    == locationService.validDeviceLocationName
            {
                didAddCurrent = true
                context.types.append(.current)
            }

            contextMap[secondsFromGmt, default: [:]][
                location.coordinateId
            ] = context
        }

        // Add in the current location if it didn't match the other locations.
        if shouldDisplayCurrent,
            !didAddCurrent
        {
            contextMap[currentTimeZoneSecondsFromGmt, default: [:]][
                CURRENT_ID
            ] =
                LocationContext(types: [.current])
        }

        return contextMap.mapValues { Array($0.values) }
    }

    private var sortedTimezones: [TimeZone] {
        locationContextsByTimeZoneSecondsFromGmt.keys
            .sorted(by: sortTimeZoneSecondsFromGmt)
            .compactMap(TimeZone.init(secondsFromGMT:))
    }

    private var flaggedMessage: String {
        guard plannerEvent.isFlagged
        else { return "" }

        if !plannerEvent.completedOn.isEmpty
            && planner.datestamp == eventDatestamp
        {
            let formattedCompletionDate = DateFormat.dateLabel.string(
                from: plannerEvent.completedOn,
                todaystamp: todayService.todaystamp,
                ordinal: true
            )

            return "Completed on \(formattedCompletionDate)"
        }

        guard eventDatestamp != planner.datestamp
        else { return "" }

        if let time = plannerEvent.time {
            let timeString =
                DateInRegion(
                    time,
                    region: plannerRegion
                ).timeString ?? ""

            return
                "\(formatDatestamp(eventDatestamp, ordinal: true)) \(timeString)"

        }

        return formatDatestamp(eventDatestamp)
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top) {
            if plannerEvent.isFlagged {
                AdornedValue(
                    flaggedMessage,
                    iconConfig: IconConfig(
                        name: "flag.fill",
                        primaryColor: plannerEvent.tint(
                            accentColor: accentColor
                        )
                    ),
                    color: Color.secondary,
                    scale: 0.7
                )
            }

            Grid(horizontalSpacing: 4, verticalSpacing: 6) {
                ForEach(
                    sortedTimezones,
                    id: \.identifier
                ) { timeZone in
                    if let contexts =
                        locationContextsByTimeZoneSecondsFromGmt[
                            timeZone.secondsFromGMT()
                        ]
                    {
                        timeZoneRow(
                            timeZone: timeZone,
                            locationContexts: contexts
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: handleEventClick)
    }

    // MARK: - View Builders

    private func timeZoneRow(
        timeZone: TimeZone,
        locationContexts: [LocationContext]
    ) -> some View {
        let time = plannerEvent.time
        let timeAndDay =
            time != nil
            ? DateInRegion(
                time!,
                region: Region(
                    calendar: Calendar.current,
                    zone: timeZone,
                    locale: Locale.current
                )
            ) : nil

        let displayTime = timeZone.identifier != plannerTimeZoneId

        return GridRow(alignment: .top) {
            ZStack {
                if displayTime, let timeAndDay {
                    let datestamp = timeAndDay.datestamp

                    if datestamp != eventDatestamp {
                        Value(
                            formatDatestamp(datestamp, ordinal: displayTime),
                            color: .secondary,
                            scale: SCALE
                        )
                    }
                }
            }
            .gridColumnAlignment(.trailing)

            ZStack {
                if displayTime,
                    let timeAndDay,
                    let timeString = timeAndDay.timeString
                {
                    Value(
                        timeString,
                        color: .secondary,
                        scale: SCALE
                    )
                }
            }
            .gridColumnAlignment(.trailing)

            VStack(alignment: .trailing, spacing: 4) {
                ForEach(
                    locationContexts.sorted(
                        by: sortLocationContexts
                    )
                ) { context in
                    AdornedValue(
                        context.locationName(
                            deviceLocationName: locationService
                                .validDeviceLocationName
                        ).withoutLocationContext,
                        additionalIconConfigs: context.types.map {
                            $0.iconConfig(
                                event: plannerEvent,
                                accentColor: accentColor
                            )
                        },
                        endAdorned: true,
                        color: .secondary,
                        scale: SCALE
                    )
                }
            }
            .gridColumnAlignment(.trailing)
        }
    }

    // MARK: - Functions

    /// Sorts geographically from East to West.
    private func sortTimeZoneSecondsFromGmt(
        lhsTimeZoneSeconds: Int,
        rhsTimeZoneSeconds: Int
    ) -> Bool {
        return lhsTimeZoneSeconds < rhsTimeZoneSeconds
    }

    /// Sorts alphabetically. Current location is always shifted to the bottom.
    private func sortLocationContexts(
        lhs: LocationContext,
        rhs: LocationContext
    ) -> Bool {
        guard let lhsLocation = lhs.location else {
            return false
        }

        guard let rhsLocation = rhs.location else {
            return true
        }

        return lhsLocation.name < rhsLocation.name
    }

    private func formatDatestamp(_ datestamp: String, ordinal: Bool = false)
        -> String
    {
        datestamp.proximityFormat(
            using: [
                ProximityRule(
                    proximity: .withinADay,
                    format: .countdown
                ),
                ProximityRule(
                    proximity: .fallback,
                    format: .conciseDateLabel,
                    ordinal: ordinal
                ),
            ],
            todaystamp: todayService.todaystamp
        )
    }
}
