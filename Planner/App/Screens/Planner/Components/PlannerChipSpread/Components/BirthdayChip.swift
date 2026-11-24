//
//  BirthdayChip.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import Contacts
import EventKit
import SwiftUI

struct BirthdayChipView: View {
    let item: PlannerBirthdayItem
    let settings: Settings
    let namespace: Namespace.ID

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var plannerEngine: ListEngine<PlannerItem>

    @State private var showContactSheet: Bool = false

    private var contactPhotoExists: Bool {
        item.thumbnailData != nil
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
            chip: item,
            disabled: plannerEngine.isSelectMode,
            settings: settings
        )
        .padding(.leading, leadingPadding)
        .glassChip(
            color: plannerEngine.dimWhenSelecting
                ?? (contactPhotoExists
                    ? nil
                    : item.ekEvent.calendarColor(accentColor: accentColor)),
            height: PlannerLayout.CHIP_HEIGHT,
            onTap: plannerEngine.isSelectMode
                ? nil
                : {
                    showContactSheet = true
                }
        )
        .matchedTransitionSource(
            id: item.id,
            in: namespace
        )

        // MARK: Contact Form
        /// Note: Contact edits are picked up by the loader's CNContactStoreDidChange observer.
        .sheet(isPresented: $showContactSheet) {
            ContactFormView(contactIdentifier: item.contactIdentifier)
                .ignoresSafeArea()
                .navigationTransition(
                    .zoom(
                        sourceID: item.id,
                        in: namespace
                    )
                )
        }
    }
}
