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
    private let plannerRegion: Region
    private let scale: CGFloat
    private let openEventSheet: (() -> Void)?

    init(
        plannerEvent: PlannerEvent,
        plannerRegion: Region,
        scale: CGFloat = 1,
        openEventSheet: (() -> Void)? = nil
    ) {
        self.plannerEvent = plannerEvent
        self.plannerRegion = plannerRegion
        self.scale = scale
        self.openEventSheet = openEventSheet
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    // MARK: - Body

    var body: some View {
        if let time = plannerEvent.time {
            Time(
                timeInRegion: DateInRegion(time, region: plannerRegion),
                color: plannerEvent.tint(accentColor: accentColor),
                scale: scale,
                onTap: openEventSheet
            )
        }
    }
}
