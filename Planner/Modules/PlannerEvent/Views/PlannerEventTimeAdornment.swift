//
//  PlannerEventTimeAdornment.swift
//  Planner
//
//  Created by Alex Green on 6/1/26.
//

import SwiftDate
import SwiftUI

struct PlannerEventTimeAdornmentView: View {
    private let plannerEvent: PlannerEvent
    private let plannerDatestamp: String
    private let plannerRegion: Region
    private let scale: CGFloat
    private let handleEventClick: (() -> Void)?

    init(
        plannerEvent: PlannerEvent,
        plannerDatestamp: String,
        plannerRegion: Region,
        scale: CGFloat = 1,
        handleEventClick: (() -> Void)? = nil
    ) {
        self.plannerEvent = plannerEvent
        self.plannerDatestamp = plannerDatestamp
        self.plannerRegion = plannerRegion
        self.scale = scale
        self.handleEventClick = handleEventClick
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    // MARK: - Body

    var body: some View {
        if let time = plannerEvent.time,
            eventDatestamp(time: time) == plannerDatestamp
        {
            Time(
                timeInRegion: DateInRegion(time, region: plannerRegion),
                color: plannerEvent.tint(accentColor: accentColor),
                scale: scale,
                onTap: handleEventClick
            )
        }
    }

    // MARK: - Functions

    private func eventDatestamp(time: Date) -> String {
        DatestampFormatter.datestamp(
            from: time,
            timeZone: plannerRegion.timeZone
        )
    }
}
