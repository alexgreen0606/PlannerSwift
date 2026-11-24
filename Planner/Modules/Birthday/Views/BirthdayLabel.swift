//
//  BirthdayLabel.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import EventKit
import SwiftUI

struct BirthdayLabelView: View {
    let chip: PlannerBirthdayItem
    var disabled: Bool = false
    var lineLimit: Int? = nil
    var scale: CGFloat = 1
    let settings: Settings

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    private var disabledColor: Color? {
        disabled ? Color.tertiary : nil
    }

    private var contactPhoto: UIImage? {
        guard let imageData = chip.thumbnailData else {
            return nil
        }

        return UIImage(data: imageData)
    }

    private var calendarColor: Color {
        chip.ekEvent.calendarColor(accentColor: accentColor)
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

                Value(chip.title, color: disabledColor, scale: scale)
                    .lineLimit(lineLimit)
            }
        } else {
            AdornedValue(
                chip.title,
                iconConfig: IconConfig(
                    name: chip.ekEvent.calendarSystemImageName(
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
