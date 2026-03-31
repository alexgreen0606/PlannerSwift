//
//  WeekdayIcon.swift
//  Planner
//
//  Created by Alex Green on 3/31/26.
//

import SwiftDate
import SwiftUI

// Clean

struct WeekdayIconView: View {
    private let day: DateInRegion
    private let size: CGFloat?

    init(
        day: DateInRegion,
        size: CGFloat? = nil
    ) {
        self.day = day
        self.size = size

        self.scale = (size ?? self.defaultSize) / self.defaultSize
    }

    private let defaultSize: CGFloat = 28
    private let scale: CGFloat

    private var scaledIconSize: CGFloat {
        defaultSize * scale
    }

    private var scaledFontSize: CGFloat {
        7 * scale
    }

    private var scaledFontOffset: CGFloat {
        13 * scale
    }

    var body: some View {
        ZStack(alignment: .top) {
            Image(systemName: "note")
                .fixedSize()
                .foregroundStyle(Color.secondary)
                .font(.system(size: scaledIconSize))

            Text(day.shortWeekday)
                .font(.system(size: scaledFontSize))
                .fontWeight(.black)
                .foregroundStyle(Color.label)
                .offset(y: scaledFontOffset)
        }
        .frame(width: scaledIconSize, height: scaledIconSize)
    }

}
