//
//  BirthdayLabel.swift
//  Planner
//
//  Created by Alex Green on 4/1/26.
//

import Contacts
import EventKit
import SwiftUI

struct BirthdayLabelView: View {
    let plannerEvent: PlannerEvent
    let settings: Settings

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    private var contactPhoto: UIImage? {
        guard
            let imageData = plannerEvent.eKEventContext?.birthdayThumbnailData
        else {
            return nil
        }

        return UIImage(data: imageData)
    }

    private var calendarColor: Color {
        plannerEvent.tint(accentColor: accentColor)
    }

    // MARK: - Body

    var body: some View {
        if let contactPhoto {
            HStack(spacing: 6) {
                Image(uiImage: contactPhoto)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())

                Value(plannerEvent.title)
            }
        } else {
            AdornedValue(
                plannerEvent.title,
                iconConfig: IconConfig(
                    name: plannerEvent.calendarSystemImageName(
                        settings: settings
                    ),
                    primaryColor: calendarColor,
                    secondaryColor: calendarColor
                ),
                color: calendarColor
            )
        }
    }
}
