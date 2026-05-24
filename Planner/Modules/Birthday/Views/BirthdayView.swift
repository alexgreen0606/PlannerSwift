//
//  BirthdayView.swift
//  Planner
//
//  Created by Alex Green on 4/1/26.
//

import Contacts
import EventKit
import SwiftUI

struct BirthdayView: View {
    let birthday: Birthday
    let settings: PlannerSettings

    private var contactPhoto: UIImage? {
        guard let imageData = birthday.contact.thumbnailImageData else {
            return nil
        }
        return UIImage(data: imageData)
    }

    private var calendarColor: Color {
        birthday.event.calendar.color
    }

    var body: some View {
        if let contactPhoto {
            HStack(spacing: 6) {
                Image(uiImage: contactPhoto)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())

                Value(birthday.event.title)
            }
        } else {
            AdornedValue(
                birthday.event.title,
                iconConfig: IconConfig(
                    name: birthday.event.calendar.systemImageName(
                        settings: settings
                    ),
                    primaryColor: calendarColor
                ),
                color: calendarColor
            )
        }
    }
}
