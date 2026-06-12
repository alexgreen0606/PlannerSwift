//
//  BirthdayChip.swift
//  Planner
//
//  Created by Alex Green on 4/1/26.
//

import Contacts
import EventKit
import SwiftUI

struct BirthdayChipView: View {
    let plannerEvent: PlannerEvent
    let settings: PlannerSettings
    let namespace: Namespace.ID

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @State private var showContactSheet: Bool = false

    private var contactPhotoExists: Bool {
        plannerEvent.calendarContext?.birthdayThumbnailData != nil
    }

    /// Shifts the icon to align with the chip border.
    private var leadingPadding: CGFloat {
        guard contactPhotoExists else {
            return 0
        }

        return 2 - (PlannerLayout.CHIP_HEIGHT / 3)
    }

    // MARK: - Body

    var body: some View {
        BirthdayLabelView(plannerEvent: plannerEvent, settings: settings)
            .padding(.leading, leadingPadding)
            .glassChip(
                color: contactPhotoExists
                    ? nil : plannerEvent.tint(accentColor: accentColor),
                height: PlannerLayout.CHIP_HEIGHT,
                onTap: {
                    showContactSheet = true
                }
            )
            .matchedTransitionSource(
                id: plannerEvent.transitionId,
                in: namespace
            )

            // MARK: Contact Form

            .sheet(isPresented: $showContactSheet) {
                ContactFormView(plannerEvent: plannerEvent)
                    .ignoresSafeArea()
                    .navigationTransition(
                        .zoom(
                            sourceID: plannerEvent.transitionId,
                            in: namespace
                        )
                    )
            }
    }
}
