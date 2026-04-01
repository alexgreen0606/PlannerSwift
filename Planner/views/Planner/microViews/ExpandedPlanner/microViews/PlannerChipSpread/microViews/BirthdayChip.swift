//
//  BirthdayChip.swift
//  Planner
//
//  Created by Alex Green on 4/1/26.
//

import Contacts
import EventKit
import SwiftUI

// Clean

struct BirthdayChipView: View {
    let birthday: Birthday
    let settings: PlannerSettings
    let openContactSheet: (Birthday) -> Void

    private var contactPhotoExists: Bool {
        birthday.contact.thumbnailImageData != nil
    }

    private var leadingPadding: CGFloat {
        guard contactPhotoExists else {
            return 0
        }
        return 4 - (PlannerLayout.CHIP_HEIGHT / 3)
    }

    var body: some View {
        BirthdayView(birthday: birthday, settings: settings)
            .padding(.leading, leadingPadding)
            .glassChip(
                color: contactPhotoExists ? nil : birthday.event.calendar.color
            ) {
                openContactSheet(birthday)
            }
    }
}
