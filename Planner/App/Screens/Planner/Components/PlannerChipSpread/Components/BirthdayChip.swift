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
    let birthday: Birthday
    let settings: PlannerSettings
    let namespace: Namespace.ID

    @State private var showContactSheet: Bool = false

    private var contactPhotoExists: Bool {
        birthday.contact.thumbnailImageData != nil
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
        BirthdayLabelView(birthday: birthday, settings: settings)
            .padding(.leading, leadingPadding)
            .glassChip(
                color: contactPhotoExists ? nil : birthday.event.calendar.color,
                height: PlannerLayout.CHIP_HEIGHT,
                onTap: {
                    showContactSheet = true
                }
            )
            .matchedTransitionSource(
                id: birthday.event.transitionId,
                in: namespace
            )

            // MARK: Contact Form

            .sheet(isPresented: $showContactSheet) {
                ContactFormView(contact: birthday.contact)
                    .ignoresSafeArea()
                    .navigationTransition(
                        .zoom(
                            sourceID: birthday.event.transitionId,
                            in: namespace
                        )
                    )
            }
    }
}
