//
//  PlannerChipSpread.swift
//  Planner
//
//  Created by Alex Green on 12/17/25.
//

import Contacts
import ContactsUI
import EventKit
import SwiftData
import SwiftDate
import SwiftUI
import WeatherKit
import WrappingHStack

// Clean

struct PlannerChipSpreadView: View {
    let planner: Planner
    let plannerDay: DateInRegion
    let sortedPlannerEvents: [PlannerEvent]
    let plannerChipEvents: [EKEvent]
    var namespace: Namespace.ID
    let settings: PlannerSettings
    let plannerLocation: Location?
    let openCalendarEventSheet: (EKEvent) -> Void

    init(
        planner: Planner,
        plannerDay: DateInRegion,
        sortedPlannerEvents: [PlannerEvent],
        plannerChipEvents: [EKEvent],
        namespace: Namespace.ID,
        settings: PlannerSettings,
        plannerLocation: Location?,
        openCalendarEventSheet: @escaping (EKEvent) -> Void
    ) {
        self.planner = planner
        self.plannerDay = plannerDay
        self.sortedPlannerEvents = sortedPlannerEvents
        self.plannerChipEvents = plannerChipEvents
        self.namespace = namespace
        self.settings = settings
        self.plannerLocation = plannerLocation
        self.openCalendarEventSheet = openCalendarEventSheet

        let contactIds: [String] = plannerChipEvents.compactMap {
            guard $0.calendar.type == .birthday else { return nil }
            return $0.birthdayContactIdentifier
        }

        guard !contactIds.isEmpty else {
            self.contactsMap = [:]
            return
        }

        // Fetch all contacts at once.
        var contactsMap: [String: CNContact] = [:]
        let store = CNContactStore()
        do {
            let contacts = try store.unifiedContacts(
                matching: CNContact.predicateForContacts(
                    withIdentifiers: contactIds
                ),
                keysToFetch: [
                    CNContactViewController.descriptorForRequiredKeys()
                ] as [CNKeyDescriptor]
            )

            let contactLookup = Dictionary(
                uniqueKeysWithValues: contacts.map {
                    ($0.identifier, $0)
                }
            )

            for event in plannerChipEvents {
                guard
                    event.calendar.type == .birthday,
                    let id = event.birthdayContactIdentifier,
                    let contact = contactLookup[id]
                else { continue }

                contactsMap[event.calendarItemExternalIdentifier] = contact
            }

        } catch {
            assertionFailure("ERROR PlannerChipSpreadView.init: \(error)")
        }

        self.contactsMap = contactsMap
    }

    private let contactsMap: [String: CNContact]

    let weatherUnit: UnitTemperature =
        Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .system

    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    @State private var isLocationSheetOpen = false

    // MARK: - Computed Variables

    private var locationLabel: String {
        planner.locationLabel(
            settings: settings,
            deviceLocation: deviceLocationManager.deviceLocation
        )
    }

    private var locationIconConfig: IconConfig {
        planner.locationIconConfig(
            settings: settings,
            accentColor: accentColor
        )
    }

    private var weatherData: DayWeather? {
        weatherStore.getWeather(for: plannerDay, at: plannerLocation)
    }

    private var isDarkMode: Bool {
        switch appColorScheme {
        case .dark: return true
        case .light: return false
        case .system: return systemColorScheme == .dark
        }
    }

    // MARK: - Body

    var body: some View {
        WrappingHStack(alignment: .leading) {
            tripChip
            locationChip
            weatherChip
            ForEach(
                plannerChipEvents,
                id: \.eventIdentifier,
                content: eventChip
            )
        }
        .animateAsynchronousAction(from: weatherData)
        .animateAsynchronousAction(from: locationLabel)
        .animateAsynchronousAction(from: plannerChipEvents.map(\.title))

        // Location Sheet
        .sheet(isPresented: $isLocationSheetOpen) {
            LocationSearchFormView(
                title: "Planner Location",
                mode: .planner,
                settings: settings,
                initialLocation: planner.location,
                sourcePlanner: planner,
            ) { location in
                modelContext.updatePlannerLocation(
                    for: planner,
                    to: location,
                    settings: settings,
                    storageEvents: sortedPlannerEvents
                )
            }
            .navigationTransition(
                .zoom(
                    sourceID: IdConstants.LOCATION_CHIP,
                    in: namespace
                )
            )
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private var tripChip: some View {
        if let trip = planner.trip {
            TripChipView(trip: trip, datestamp: planner.datestamp)
        }
    }

    @ViewBuilder
    private var locationChip: some View {
        if planner.trip == nil {
            PlannerChipView(
                title: locationLabel,
                iconConfig: locationIconConfig,
                color: nil,
                contact: nil,
                onTap: {
                    isLocationSheetOpen = true
                }
            )
            .matchedTransitionSource(
                id: IdConstants.LOCATION_CHIP,
                in: namespace
            )
        }
    }

    @ViewBuilder
    private var weatherChip: some View {
        if let weatherData {
            HStack(alignment: .center, spacing: 8) {
                HStack(alignment: .center, spacing: 4) {
                    Image(systemName: weatherData.symbolName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .symbolVariant(isDarkMode ? .fill : .none)
                        .symbolRenderingMode(
                            isDarkMode ? .multicolor : .monochrome
                        )

                    Text(weatherData.condition.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.label)
                }

                HStack(alignment: .center, spacing: 4) {
                    Text(weatherData.highTemp(in: weatherUnit))
                        .font(
                            .system(
                                size: 11,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(Color.label)

                    Divider().frame(height: 16)

                    Text(weatherData.lowTemp(in: weatherUnit))
                        .font(
                            .system(
                                size: 10,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(Color.label)
                }
            }
            .glassChip(color: nil, onTap: openWeatherApp)
            .contentShape(Rectangle())
            .onTapGesture(perform: openWeatherApp)
        }
    }

    @ViewBuilder
    private func eventChip(_ event: EKEvent) -> some View {
        PlannerChipView(
            title: event.title,
            iconConfig: IconConfig(
                name: event.calendar.systemImageName(settings: settings),
                primaryColor: event.calendar.color
            ),
            color: event.calendar.color,
            contact: contactsMap[event.calendarItemExternalIdentifier]
        ) {
            openCalendarEventSheet(event)
        }
        .matchedTransitionSource(
            id: event.transitionId,
            in: namespace
        )
    }

    // MARK: - Functions

    private func openWeatherApp() {
        guard let url = URL(string: "weather://") else { return }
        UIApplication.shared.open(url)
    }

}
