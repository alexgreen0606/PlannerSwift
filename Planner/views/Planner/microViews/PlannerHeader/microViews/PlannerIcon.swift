//
//  PlannerIcon.swift
//  Planner
//
//  Created by Alex Green on 12/21/25.
//

import SwiftDate
import SwiftUI

// Clean

struct PlannerIconView: View {
    private let datestamp: String
    private let format: DateFormat
    private let customSize: CGFloat?
    private let customDetailSize: CGFloat?
    private let customDetailOffset: CGFloat?

    init(
        datestamp: String,
        format: DateFormat,
        size: CGFloat? = nil,
        detailSize: CGFloat? = nil,
        detailOffset: CGFloat? = nil
    ) {
        self.datestamp = datestamp
        self.format = format
        self.customSize = size
        self.customDetailSize = detailSize
        self.customDetailOffset = detailOffset
    }

    private let defaultSize: CGFloat = 40

    private let defaultMonthSize: CGFloat = 9
    private let defaultMonthOffset: CGFloat = 1.5
    private let defaultWeekdaySize: CGFloat = 11
    private let defaultWeekdayOffset: CGFloat = 17.4

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @EnvironmentObject private var todaystampManager: TodaystampWatcher

    // MARK: Icon

    private var primaryIconColor: Color {
        format == .shortMonth ? .label : .tertiary
    }

    private var secondaryIconColor: Color {
        datestamp == todaystampManager.todaystamp
            ? accentColor.color : .secondary
    }

    private var imageSystemName: String {
        format == .shortMonth ? datestamp.calendarSymbolName : "note"
    }

    private var size: CGFloat {
        customSize ?? defaultSize
    }

    // MARK: Detail Text

    private var detail: String {
        format == .shortMonth ? datestamp.shortMonth : datestamp.shortWeekday
    }

    private var detailSize: CGFloat {
        customDetailSize
            ?? (format == .shortMonth ? defaultMonthSize : defaultWeekdaySize)
    }

    private var detailOffset: CGFloat {
        customDetailOffset
            ?? (format == .shortMonth
                ? defaultMonthOffset : defaultWeekdayOffset)
    }

    private var detailColor: Color {
        format == .shortMonth
            ? Color.inverseLabel : Color.label
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            Image(systemName: imageSystemName)
                .fixedSize()
                .font(.system(size: size))
                .foregroundStyle(primaryIconColor, secondaryIconColor)

            Text(detail)
                .font(.system(size: detailSize))
                .fontWeight(.black)
                .fontDesign(.rounded)
                .foregroundStyle(detailColor)
                .offset(y: detailOffset)
        }
    }
}
