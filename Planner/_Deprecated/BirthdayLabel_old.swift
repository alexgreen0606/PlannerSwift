//
//  BirthdayLabel.swift
//  Planner
//
//  Created by Alex Green on 4/1/26.
//

import Contacts
import EventKit
import SwiftUI

struct BirthdayLabelView_old: View {
    private let plannerEvent: PlannerEvent
    private let disabled: Bool
    private let lineLimit: Int?
    private let scale: CGFloat
    private let settings: Settings

    init(
        plannerEvent: PlannerEvent,
        disabled: Bool = false,
        lineLimit: Int? = nil,
        scale: CGFloat = 1,
        settings: Settings
    ) {
        self.plannerEvent = plannerEvent
        self.disabled = disabled
        self.lineLimit = lineLimit
        self.scale = scale
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
        plannerEvent.calendarColor(accentColor: accentColor)
    }

    // MARK: - Body

    var body: some View {
        if let contactPhoto {
            HStack(spacing: Layout.DEFAULT_ADORNMENT_SPACING) {
                Image(uiImage: contactPhoto)
                    .resizable()
                    .scaledToFill()
                    .opacity(disabled ? 0.2 : 1)
                    .frame(width: 24 * scale, height: 24 * scale)
                    .clipShape(Circle())

                Value(plannerEvent.title, color: disabledColor, scale: scale)
                    .lineLimit(lineLimit)
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
                lineLimit: lineLimit,
                color: disabledColor ?? .label,
                scale: scale
            )
        }
    }
}
