//
//  PlannerBuilder.swift
//  Planner
//
//  Created by Alex Green on 2/15/26.
//

import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct PlannerBuilderView<Header: View>: View {
    private let datestamp: String
    private let settings: PlannerSettings
    private let previewType: PlannerPreviewType?
    private let plannerSearchQuery: PlannerSearchQuery?
    private let header: Header
    private let namespace: Namespace.ID?
    private let transitionSource: String?

    init(
        datestamp: String,
        settings: PlannerSettings,
        previewType: PlannerPreviewType? = nil,
        plannerSearchQuery: PlannerSearchQuery? = nil,
        header: Header,
        namespace: Namespace.ID? = nil,
        transitionSource: String? = nil
    ) {
        self.datestamp = datestamp
        self.previewType = previewType
        self.plannerSearchQuery = plannerSearchQuery
        self.header = header
        self.settings = settings
        self.namespace = namespace
        self.transitionSource = transitionSource

        _planners = Query(
            filter: #Predicate<Planner> {
                $0.datestamp == datestamp
            }
        )
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var plannerCoverManager: PlannerCoverManager
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    @Query private var planners: [Planner]

    private var planner: Planner? {
        planners.first
    }

    private var plannerDay: DateInRegion? {
        guard let planner else {
            return nil
        }
        return datestamp.startOfDay(in: planner.region(settings: settings))
    }

    private var plannerLocation: Location? {
        guard let planner else {
            return nil
        }
        return planner.location(
            settings: settings,
            deviceLocation: deviceLocationManager.deviceLocation
        )
    }

    var body: some View {
        if let previewType {
            preview(type: previewType)
        } else {
            eventList
        }
    }

    // MARK: - View Builders

    private var eventList: some View {
        ZStack {
            if let planner, let plannerDay {
                PlannerEventBuilderView(
                    planner: planner,
                    plannerDay: plannerDay,
                    plannerLocation: plannerLocation,
                    settings: settings,
                    previewType: previewType,
                    plannerSearchQuery: plannerSearchQuery,
                    header: header
                )
            }
        }
        .task {
            modelContext.ensurePlanner(planners: planners, datestamp: datestamp)
        }
    }

    @ViewBuilder
    private func preview(type: PlannerPreviewType) -> some View {
        if let namespace {
            ZStack {
                if previewType != .search {
                    previewCard
                } else {
                    searchPreview
                }
            }
            .matchedTransitionSource(
                id: transitionSource ?? datestamp,
                in: namespace
            )
            .contentShape(Rectangle())
            .onTapGesture {
                plannerCoverManager.context = PlannerCoverContext(
                    datestamp: datestamp,
                    source: transitionSource
                )
            }
        }
    }

    private var previewCard: some View {
        VStack(alignment: .leading) {
            previewHeader
            eventList
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .center
                )
            if let plannerDay, let planner {
                PreviewCardWeatherView(
                    planner: planner,
                    plannerDay: plannerDay,
                    plannerLocation: plannerLocation,
                    settings: settings
                )
            }
        }
        .padding()
        .frame(
            width: todaystampWatcher.todaystamp == datestamp
                && previewType != .trip ? 350 : 240,
            height: PlannerLayout.PREVIEW_CARD_HEIGHT,
            alignment: .top
        )
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardBackground)
        )
    }

    private var searchPreview: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                previewHeader
                Spacer()
                if let planner, let plannerDay,
                    let plannerSearchQuery
                {
                    SearchResultsWeatherView(
                        plannerSearchQuery: plannerSearchQuery,
                        planner: planner,
                        plannerDay: plannerDay,
                        plannerLocation: plannerLocation,
                        settings: settings
                    )
                }
            }
            eventList
        }
    }

    private var previewHeader: some View {
        header
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

}
