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
    private let plannerEvent: PlannerEvent
    private let settings: Settings
    private let disabled: Bool
    
    init(
        plannerEvent: PlannerEvent,
        disabled: Bool = false,
        settings: Settings
    ) {
        self.plannerEvent = plannerEvent
        self.disabled = disabled
        self.settings = settings
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue
    
    private var disabledColor: Color? {
        disabled ? Color.tertiary : nil
    }

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
            HStack(spacing: Layout.DEFAULT_ADORNMENT_SPACING) {
                Image(uiImage: contactPhoto)
                    .resizable()
                    .scaledToFill()
                    .opacity(disabled ? 0.2 : 1)
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())

                Value(plannerEvent.title, color: disabledColor)
            }
        } else {
            AdornedValue(
                plannerEvent.title,
                iconConfig: IconConfig(
                    name: plannerEvent.calendarSystemImageName(
                        settings: settings
                    ),
                    primaryColor: disabledColor ?? calendarColor,
                    secondaryColor: disabledColor ?? calendarColor
                ),
                color: disabledColor ?? calendarColor
            )
        }
    }
}
