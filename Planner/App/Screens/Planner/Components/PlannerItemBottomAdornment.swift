//
//  PlannerItemBottomAdornment.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import EventKit
import SwiftDate
import SwiftUI

struct PlannerItemBottomAdornmentView: View {
    let item: PlannerItem
    let planner: Planner
    let settings: Settings

    private let CURRENT_ID = "CURRENT"
    private let SCALE: CGFloat = 0.65

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var listEngine: ListEngine<PlannerItem>

    /// Reflects in-progress draft edits (ex: toggling the flag from the keyboard toolbar).
    /// Note: Drafts outlive editing sessions and aren't synced by external edits (ex: the event form),
    /// so the draft is only trusted while this item is actively being edited.
    private var isFlagged: Bool {
        guard let plannerEvent = item.plannerEvent else { return false }

        if let activeEditor = listEngine.activeEditor,
            activeEditor.belongs(to: item.id)
        {
            return activeEditor.draft.isFlagged
        }

        return plannerEvent.isFlagged
    }

    private var eventLocation: Location? {
        switch item.source {
        case .plannerEvent(let plannerEvent):
            plannerEvent.location
        case .ekEvent(let ekEvent, state: _):
            ekEvent.location()
        }
    }

    /// This is the datestamp the event lands in relative to the planner's region.
    private var eventDatestamp: String {
        if let time = item.time {
            // Timed event: placed in a day from the perspective of the planner.
            return DatestampFormatter.datestamp(
                from: time,
                timeZone: plannerRegion.timeZone
            )
        } else if let datestamp = item.plannerEvent?.datestamp {
            // Untimed event: placed directly in its parent planner.
            return datestamp
        } else {
            // Fallback that should never occur in theory.
            return planner.datestamp
        }
    }

    /// Used to ensure that timezones are evaluated with the correct DST offset.
    private var eventTime: Date {
        item.time ?? Date()
    }

    private var plannerRegion: Region {
        planner.region(settings: settings)
    }

    private var locationContextsByTimeZoneSecondsFromGmt:
        [Int: [LocationContext]]
    {
        let typedLocations: [TypedLocation] = [
            TypedLocation(location: eventLocation, type: .event),
            TypedLocation(location: settings.homeLocation, type: .home),
            TypedLocation(location: planner.trip?.location, type: .trip),
        ]

        var contextMap: [Int: [String: LocationContext]] = [:]

        let currentSecondsFromGmt = TimeZone.current.secondsFromGMT(
            for: eventTime
        )
        let shouldDisplayCurrent = shouldDisplayLocation(
            .current,
            locationSecondsFromGmt: currentSecondsFromGmt,
            settings: settings
        )
        var didAddCurrent = false

        for typedLocation in typedLocations {
            guard
                let location = typedLocation.location,
                shouldDisplayLocation(
                    typedLocation.type,
                    locationSecondsFromGmt: location.region.timeZone
                        .secondsFromGMT(for: eventTime),
                    settings: settings
                ),
                let secondsFromGmt = TimeZone(
                    identifier: location.timeZoneIdentifier
                )?.secondsFromGMT(for: eventTime)
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
                secondsFromGmt == currentSecondsFromGmt,
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
            contextMap[currentSecondsFromGmt, default: [:]][
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

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top) {
            if isFlagged {
                AdornedValue(
                    "",
                    iconConfig: IconConfig(
                        name: "flag.fill",
                        primaryColor: accentColor.swiftUiColor
                    ),
                    color: Color.secondary,
                    scale: 0.7
                )
            }

            PlannerItemCalendarAdornmentView(
                item: item,
                settings: settings
            )

            Grid(horizontalSpacing: 4, verticalSpacing: 6) {
                ForEach(
                    sortedTimezones,
                    id: \.identifier
                ) { timeZone in
                    if let contexts =
                        locationContextsByTimeZoneSecondsFromGmt[
                            timeZone.secondsFromGMT(for: eventTime)
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
    }

    // MARK: - View Builders

    private func timeZoneRow(
        timeZone: TimeZone,
        locationContexts: [LocationContext]
    ) -> some View {
        let time = item.time
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

        let displayTime =
            timeZone.secondsFromGMT(for: eventTime)
            != plannerRegion.timeZone.secondsFromGMT(for: eventTime)

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
                            locationIconConfig(for: $0)
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

    private func shouldDisplayLocation(
        _ type: LocationType,
        locationSecondsFromGmt: Int,
        settings: Settings
    ) -> Bool {
        let plannerLocation = planner.location(settings: settings)

        switch type {
        case .home, .trip, .current:
            let eventIsTimed = item.time != nil
            let hasDifferentTimeThanPlanner =
                locationSecondsFromGmt
                != plannerLocation?.region.timeZone.secondsFromGMT(
                    for: item.time ?? Date()
                )

            return eventIsTimed && hasDifferentTimeThanPlanner
        case .event:
            let eventCoordinateId = (eventLocation ?? plannerLocation)?
                .coordinateId

            return eventCoordinateId != plannerLocation?.coordinateId
        }
    }

    private func locationIconConfig(for type: LocationType) -> IconConfig {
        switch type {
        case .home:
            return IconConfig(name: "house")
        case .trip:
            return IconConfig(name: "suitcase")
        case .event:
            return IconConfig(
                name: "mappin.and.ellipse",
                primaryColor: accentColor.swiftUiColor
            )
        case .current:
            return IconConfig(name: "location")
        }
    }

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
