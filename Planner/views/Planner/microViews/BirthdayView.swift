//
//  BirthdayView.swift
//  Planner
//
//  Created by Alex Green on 4/1/26.
//

import Contacts
import EventKit
import SwiftUI

// Clean

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
        HStack(spacing: 6) {
            if let contactPhoto {
                Image(uiImage: contactPhoto)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
            } else {
                Image(
                    systemName: birthday.event.calendar.systemImageName(
                        settings: settings
                    )
                )
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .foregroundStyle(
                    birthday.event.calendar.color
                )
            }

            Text(birthday.event.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(
                    contactPhoto != nil ? Color.label : calendarColor
                )
        }
    }
}
