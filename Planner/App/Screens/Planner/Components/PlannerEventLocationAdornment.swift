//
//  PlannerEventLocationAdornment.swift
//  Planner
//
//  Created by Alex Green on 2/27/26.
//

import SwiftDate
import SwiftUI

struct PlannerEventLocationAdornmentView: View {
    let plannerEvent: PlannerEvent
    let planner: Planner
    let settings: Settings
    let openEventSheet: () -> Void

    private let CURRENT_ID = "CURRENT"
    private let SCALE: CGFloat = 0.65

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var locationService: LocationService

    private var plannerTimeZoneId: String {
        planner.location(settings: settings).timeZoneId
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
            .compactMap(TimeZone.init(secondsFromGMT:))
            .sorted(by: sortTimeZones)
    }

    // MARK: - Body

    var body: some View {
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
        .contentShape(Rectangle())
        .onTapGesture(perform: openEventSheet)
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

                    if datestamp != planner.datestamp {
                        Value(
                            datestamp.weekday,
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

    /// Sorts geographically from East to West. Planner time zone is always shifted to the top.
    private func sortTimeZones(
        lhsTimeZone: TimeZone,
        rhsTimeZone: TimeZone
    ) -> Bool {
        guard lhsTimeZone.identifier != plannerTimeZoneId else {
            return true
        }

        guard rhsTimeZone.identifier != plannerTimeZoneId else {
            return false
        }

        let now = Date()
        let lhsOffset = lhsTimeZone.secondsFromGMT(for: now)
        let rhsOffset = rhsTimeZone.secondsFromGMT(for: now)

        return lhsOffset < rhsOffset
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
}
