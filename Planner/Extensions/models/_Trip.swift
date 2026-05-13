//
//  _Trip.swift
//  Planner
//
//  Created by Alex Green on 3/22/26.
//

import Foundation
import Fuse
import SwiftUI

extension Trip {

    var safePlanners: [Planner] {
        self.planners ?? []
    }

    var sortedPlanners: [Planner] {
        safePlanners.sorted { $0.datestamp < $1.datestamp }
    }

    var firstDatestamp: String? {
        sortedPlanners.first?.datestamp
    }

    var lastDatestamp: String? {
        sortedPlanners.last?.datestamp
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
        accentColor: AccentColor,
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
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.color,
                            accentColor.color.opacity(0.7),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: progressBarWidth * tripProgress)
                .animation(.easeInOut(duration: 0.3), value: tripProgress)
        }
        .frame(height: 8)
    }

    func dateRangeLabel(todaystamp: String) -> String {
        guard let firstDatestamp,
            let lastDatestamp
        else {
            return ""
        }

        return buildDateRangeLabel(
            firstDatestamp: firstDatestamp,
            lastDatestamp: lastDatestamp,
            todaystamp: todaystamp,
            referenceYear: firstDatestamp.year
        )
    }

    func transitionId(for datestamp: String) -> String {
        "\(datestamp)_\(String(describing: id))"
    }

    // MARK: - Search Helper

    func searchQueryScore(_ query: PlannerSearchQuery?) -> Double?  // nil means the event doesn't match the query
    {
        guard let query else {
            // Include. No query set.
            return 1.0
        }

        guard let firstDatestamp, let lastDatestamp else {
            return nil
        }

        if !query.containsDatestampRange(
            startDatestamp: firstDatestamp,
            endDatestamp: lastDatestamp
        ) {
            // Exclude. Doesn't match the time range.
            return nil
        }

        if query.text.isEmpty {
            // Include. No search text.
            return 1.0
        }

        var score = 0.0

        if let titleScore = query.score(for: self.title) {
            // Include. Title matches the search text.
            score += titleScore
        }

        if let location = self.location,
            let locationScore = query.score(for: location.name)
        {
            // Include. Location matches the search text.
            score += locationScore
        }

        if score != 0.0 {
            return score
        }

        return nil
    }

}
