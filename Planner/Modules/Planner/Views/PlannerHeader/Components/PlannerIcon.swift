//
//  PlannerIcon.swift
//  Planner
//
//  Created by Alex Green on 12/21/25.
//

import SwiftDate
import SwiftUI

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
        customSize = size
        customDetailSize = detailSize
        customDetailOffset = detailOffset
    }

    private let defaultSize: CGFloat = 40

    private let defaultMonthSize: CGFloat = 9
    private let defaultMonthOffset: CGFloat = 1.5
    private let defaultWeekdaySize: CGFloat = 11
    private let defaultWeekdayOffset: CGFloat = 17.4

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var todaystampManager: TodaystampService

    // MARK: Icon

    private var primaryIconColor: Color {
        format == .conciseMonth ? .label : .tertiary
    }

    private var secondaryIconColor: Color {
        datestamp == todaystampManager.todaystamp
            ? accentColor.color : .secondary
    }

    private var imageSystemName: String {
        format == .conciseMonth ? datestamp.calendarSymbolName : "note"
    }

    private var size: CGFloat {
        customSize ?? defaultSize
    }

    // MARK: Detail Text

    private var detail: String {
        format == .conciseMonth ? datestamp.conciseMonth : datestamp.conciseWeekday
    }

    private var detailSize: CGFloat {
        customDetailSize
            ?? (format == .conciseMonth ? defaultMonthSize : defaultWeekdaySize)
    }

    private var detailOffset: CGFloat {
        customDetailOffset
            ?? (format == .conciseMonth
                ? defaultMonthOffset : defaultWeekdayOffset)
    }

    private var detailColor: Color {
        format == .conciseMonth
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
