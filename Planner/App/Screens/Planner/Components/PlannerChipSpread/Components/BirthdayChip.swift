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
    let settings: Settings
    let namespace: Namespace.ID

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue
    
    @EnvironmentObject private var plannerEngine: ListEngine<PlannerEvent>

    @State private var showContactSheet: Bool = false

    private var contactPhotoExists: Bool {
        plannerEvent.eKEventContext?.birthdayThumbnailData != nil
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
        BirthdayLabelView(
            plannerEvent: plannerEvent,
            disabled: plannerEngine.isSelectMode,
            settings: settings
        )
            .padding(.leading, leadingPadding)
            .glassChip(
                color: plannerEngine.selectModeDisabledColor ?? (contactPhotoExists
                    ? nil : plannerEvent.tint(accentColor: accentColor)),
                height: PlannerLayout.CHIP_HEIGHT,
                onTap: plannerEngine.isSelectMode ? nil : {
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
