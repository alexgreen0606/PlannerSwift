//
//  Trip+.swift
//  Planner
//
//  Created by Alex Green on 3/22/26.
//

import Foundation
import Fuse
import SwiftUI

extension Trip {
    var safePlanners: [Planner] {
        planners ?? []
    }

    var sortedPlanners: [Planner] {
        safePlanners.sorted { $0.datestamp < $1.datestamp }
    }

    var dateComponents: Set<DateComponents> {
        Set(
            safePlanners.compactMap { $0.datestamp.dateComponents }
        )
    }

    func day(of datestamp: String) -> CGFloat {
        guard
            let index = sortedPlanners.firstIndex(where: {
                $0.datestamp == datestamp
            })
        else {
            return 0.0
        }

        return Double(index) + 1.0
    }

    @ViewBuilder
    func progressBar(
        day: CGFloat,
        accentColor: AccentColor
    ) -> some View {
        let progressBarWidth: CGFloat = 100

        let tripProgress: Double = {
            guard sortedPlanners.count > 0 else { return 0 }
            return day / Double(sortedPlanners.count)
        }()

        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.secondary.opacity(0.15))
                .frame(width: progressBarWidth)

            Capsule()
                .fill(accentColor.color)
                .frame(width: progressBarWidth * tripProgress)
                .animation(.easeInOut(duration: 0.3), value: tripProgress)
        }
        .frame(height: 8)
    }

    func dateRangeLabel(todaystamp: String) -> String {
        buildDateRangeLabel(
            firstDatestamp: firstDatestamp,
            lastDatestamp: lastDatestamp,
            todaystamp: todaystamp,
            referenceYear: firstDatestamp.year
        )
    }

    var transitionId: String {
        "\(String(describing: id))"
    }

    func transitionId(for datestamp: String) -> String {
        "\(datestamp)_\(String(describing: id))"
    }
}
