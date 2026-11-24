//
//  PlannerListItemTimeAdornment.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import SwiftDate
import SwiftUI

struct PlannerItemTimeAdornmentView: View {
    let item: PlannerItem
    let plannerDatestamp: String
    let plannerRegion: Region
    var scale: CGFloat = 1

    // MARK: - Body

    var body: some View {
        if let time = item.time,
            DatestampFormatter.datestamp(
                from: time,
                timeZone: plannerRegion.timeZone
            ) == plannerDatestamp
        {
            Time(
                timeInRegion: DateInRegion(time, region: plannerRegion),
                scale: scale
            )
        }
    }
}
