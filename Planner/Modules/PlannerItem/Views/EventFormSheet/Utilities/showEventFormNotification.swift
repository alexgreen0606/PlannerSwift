//
//  showEventFormNotification.swift
//  Planner
//
//  Created by Alex Green on 11/23/26.
//

import SwiftUI

@MainActor
func showEventFormNotification(
    destinationDatestamps: Set<String>,
    sourceDatestamp: String?,
    todayService: TodayService,
    plannerCoverStore: PlannerCoverStore,
    showToast: (Toast) -> Void
) {
    let cutoffDatestamp = todayService.minStartOfDay.datestamp

    guard
        let earliestDatestamp =
            destinationDatestamps
            .filter({ $0 >= cutoffDatestamp })
            .sorted()
            .first
    else {
        return
    }

    guard let sourceDatestamp else {
        showToast(
            Toast(
                title: "Successfully created event!",
                subtitle:
                    "\(earliestDatestamp.dateWithYear) | \(earliestDatestamp.weekday)",
                iconConfig: IconConfig(
                    name: "calendar.day.timeline.leading",
                    primaryColor: Color.label,
                    secondaryColor: Color.secondary
                ),
                variant: .tab,
                action: {
                    plannerCoverStore.context = PlannerCoverContext(
                        datestamp: earliestDatestamp
                    )
                }
            )
        )
        return
    }

    guard !destinationDatestamps.contains(sourceDatestamp) else { return }

    let leftArrowColor =
        earliestDatestamp > sourceDatestamp
        ? Color.secondary : Color.label
    let rightArrowColor =
        earliestDatestamp > sourceDatestamp
        ? Color.label : Color.secondary

    showToast(
        Toast(
            title: "Successfully moved event!",
            subtitle:
                "\(earliestDatestamp.dateWithYear) | \(earliestDatestamp.weekday)",
            iconConfig: IconConfig(
                name: "arrow.left.arrow.right",
                primaryColor: leftArrowColor,
                secondaryColor: rightArrowColor
            ),
            action: {
                plannerCoverStore.context = PlannerCoverContext(
                    datestamp: earliestDatestamp
                )
            }
        )
    )
}
