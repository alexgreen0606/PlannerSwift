//
//  PlannerIcon.swift
//  Planner
//
//  Created by Alex Green on 12/21/25.
//

import SwiftUI

struct PlannerIconView: View {
    private let type: PlannerIconType
    private let datestamp: String

    init(
        type: PlannerIconType,
        datestamp: String,
        size: CGFloat? = nil,
        detailSize: CGFloat? = nil,
        detailOffset: CGFloat? = nil
    ) {
        self.type = type
        self.datestamp = datestamp

        customSize = size
        customDetailSize = detailSize
        customDetailOffset = detailOffset
    }

    private let customSize: CGFloat?
    private let customDetailSize: CGFloat?
    private let customDetailOffset: CGFloat?

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var todaystampService: TodayService

    // MARK: Icon

    private var systemImageName: String {
        type == .date ? datestamp.calendarSymbolName : "note"
    }

    private var size: CGFloat {
        customSize ?? PlannerIconLayout.SIZE
    }

    private var primaryIconColor: Color {
        type == .date ? .label : .tertiary
    }

    private var secondaryIconColor: Color {
        datestamp == todaystampService.todaystamp
            ? accentColor.color : .secondary
    }

    // MARK: Detail Text

    private var detail: String {
        type == .date ? datestamp.conciseMonth : datestamp.conciseWeekday
    }

    private var detailSize: CGFloat {
        customDetailSize
            ?? (type == .date
                ? PlannerIconLayout.MONTH_SIZE : PlannerIconLayout.WEEKDAY_SIZE)
    }

    private var detailOffset: CGFloat {
        customDetailOffset
            ?? (type == .date
                ? PlannerIconLayout.MONTH_OFFSET
                : PlannerIconLayout.WEEKDAY_OFFSET)
    }

    private var detailColor: Color {
        type == .date
            ? Color.inverseLabel : Color.label
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            Image(systemName: systemImageName)
                .font(.system(size: size))
                .foregroundStyle(primaryIconColor, secondaryIconColor)

            Text(detail)
                .font(
                    .system(size: detailSize, weight: .black, design: .rounded)
                )
                .foregroundStyle(detailColor)
                .offset(y: detailOffset)
        }
    }
}
