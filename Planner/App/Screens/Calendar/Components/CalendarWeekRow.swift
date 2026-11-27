//
//  CalendarWeekRow.swift
//  Planner
//
//  Created by Alex Green on 11/26/26.
//

import SwiftUI

/// A single week of the calendar.
///
/// Day cells form the bottom layer (number, today highlight, tap). Items are drawn in an
/// overlay of fixed-height lanes so they can stretch across every day they cover.
struct CalendarWeekRowView: View {
    /// The 7 datestamps of this week. Nil entries are padding cells.
    let datestamps: [String?]
    /// Nil while the month's content isn't loaded.
    let layout: CalendarWeekLayout?
    /// The full height of the row, including the cells' vertical padding.
    let height: CGFloat
    let settings: Settings
    let namespace: Namespace.ID

    // MARK: Layout Constants

    /// Padding above and below each day cell's content.
    static let VERTICAL_PADDING: CGFloat = 4
    static let DAY_NUMBER_HEIGHT: CGFloat = 22
    /// Vertical padding around the item area: the gap between the day number and the first lane,
    /// and the gap between the remaining count and the bottom of the cell.
    static let ITEM_AREA_VERTICAL_PADDING: CGFloat = 2
    static let LANE_HEIGHT: CGFloat = 14
    static let TEXT_SCALE = 0.6

    /// The height inside each cell's vertical padding.
    private var contentHeight: CGFloat {
        max(0, height - Self.VERTICAL_PADDING * 2)
    }

    /// Top of the item area, measured from the top of the row.
    private var itemAreaTop: CGFloat {
        Self.VERTICAL_PADDING + Self.DAY_NUMBER_HEIGHT
            + Self.ITEM_AREA_VERTICAL_PADDING
    }

    /// Height of the item area (lanes + remaining count), inset by its vertical padding.
    private var itemAreaHeight: CGFloat {
        max(
            0,
            contentHeight - Self.DAY_NUMBER_HEIGHT
                - Self.ITEM_AREA_VERTICAL_PADDING * 2
        )
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { column in
                if let datestamp = datestamps[column] {
                    CalendarDayCellView(
                        datestamp: datestamp,
                        height: contentHeight,
                        namespace: namespace
                    )
                } else {
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: height)
                }
            }
        }
        .overlay(alignment: .topLeading) {
            if let layout {
                GeometryReader { geo in
                    itemLayer(layout, columnWidth: geo.size.width / 7)
                }
                .frame(height: itemAreaHeight, alignment: .top)
                .clipped()
                .padding(.top, itemAreaTop)
                .allowsHitTesting(false)
            }
        }
    }

    // MARK: - View Builders

    private func itemLayer(
        _ layout: CalendarWeekLayout,
        columnWidth: CGFloat
    ) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(layout.segments) { segment in
                CalendarSegmentView(
                    segment: segment,
                    settings: settings
                )
                .frame(
                    width: columnWidth * CGFloat(segment.span),
                    height: Self.LANE_HEIGHT,
                    alignment: .leading
                )
                .clipped()
                .offset(
                    x: columnWidth * CGFloat(segment.startColumn),
                    y: Self.LANE_HEIGHT * CGFloat(segment.lane)
                )
            }

            ForEach(0..<7, id: \.self) { column in
                let count = layout.remainingCounts[column]

                if count > 0 {
                    Text("+\(count)")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.secondary)
                        .frame(width: columnWidth)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .offset(
                            x: columnWidth * CGFloat(column)
                        )
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
    }
}

// MARK: - Day Cell

private struct CalendarDayCellView: View {
    let datestamp: String
    let height: CGFloat
    let namespace: Namespace.ID

    private let BORDER_RADIUS: CGFloat = 8

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    private var isToday: Bool {
        datestamp == todayService.todaystamp
    }
    
    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            Text(String(datestamp.dayDigit ?? 0))
                .fontWeight(.heavy)
                .fontDesign(.rounded)
                .foregroundStyle(isToday ? Color.inverseLabel : Color.label)
                .frame(maxWidth: .infinity)
                .frame(height: CalendarWeekRowView.DAY_NUMBER_HEIGHT)
                .background {
                    if isToday {
                        UnevenRoundedRectangle(
                            topLeadingRadius: BORDER_RADIUS,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: BORDER_RADIUS
                        )
                        .fill(accentColor.swiftUiColor)
                    }
                }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .top)
        .overlay {
            if isToday {
                RoundedRectangle(cornerRadius: BORDER_RADIUS)
                    .strokeBorder(accentColor.swiftUiColor, lineWidth: 1)
                    .allowsHitTesting(false)
            }
        }
        .padding(.vertical, CalendarWeekRowView.VERTICAL_PADDING)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.tertiary)
                .frame(height: 1)
        }
        .matchedTransitionSource(
            id: datestamp,
            in: namespace
        )
        .contentShape(Rectangle())
        .onTapGesture {
            plannerCoverStore.context = PlannerCoverContext(
                datestamp: datestamp
            )
        }
    }
}

// MARK: - Segment

/// One item's run within a week. The title starts at the leading edge and may stretch across
/// every day the item covers, while the underline spans the full run.
private struct CalendarSegmentView: View {
    let segment: CalendarSegment
    let settings: Settings

    private let UNDERLINE_HEIGHT: CGFloat = 0.5
    private let HORIZONTAL_INSET: CGFloat = 2
    /// Fraction of a single day's width used to fade out the title (matches the old 0.7 → 1 mask).
    private let FADE_FRACTION_OF_DAY = 0.3

    /// Where the fade begins, so it always covers the last 30% of the final day.
    private var fadeStart: Double {
        1 - FADE_FRACTION_OF_DAY / Double(max(1, segment.span))
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    private var item: CalendarItem {
        segment.item
    }

    /// Sized to fit within a lane alongside the underline.
    private let CONTACT_PHOTO_SIZE: CGFloat = 11

    private var contactPhoto: UIImage? {
        guard case .birthday(let birthday) = item.kind,
            let data = birthday.thumbnailData
        else { return nil }

        return UIImage(data: data)
    }

    /// Only items that cover more than one day are underlined.
    private var underlineColor: Color? {
        guard item.spansMultipleDays else { return nil }

        return switch item.kind {
        case .trip:
            Color.secondary
        case .birthday(let birthday):
            birthday.ekEvent.calendarColor(accentColor: accentColor)
        case .ekEvent(let ekEvent):
            ekEvent.calendarColor(accentColor: accentColor)
        case .plannerEvent:
            nil
        }
    }

    private var iconConfig: IconConfig? {
        guard !segment.isContinuation else { return nil }

        switch item.kind {
        case .trip:
            return IconConfig(name: "suitcase")
        case .birthday(let birthday):
            let ekEvent = birthday.ekEvent
            let calendarColor = ekEvent.calendarColor(accentColor: accentColor)

            return IconConfig(
                name: ekEvent.calendarSystemImageName(settings: settings),
                primaryColor: calendarColor,
                secondaryColor: calendarColor
            )
        case .ekEvent(let ekEvent):
            let calendarColor = ekEvent.calendarColor(accentColor: accentColor)

            return IconConfig(
                name: ekEvent.calendarSystemImageName(settings: settings),
                primaryColor: calendarColor,
                secondaryColor: calendarColor
            )
        case .plannerEvent:
            return nil
        }
    }
    
    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Note: The label is an overlay so its natural width never affects layout.
            // It always starts at the first day and is clipped to the segment's days.
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .leading) {
                    // Note: Hides the today border where a title passes over it.
                    label
                        .background(Color.appBackground)
                }
                .clipped()
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: fadeStart),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }

            Rectangle()
                .fill(underlineColor ?? .clear)
                .frame(height: UNDERLINE_HEIGHT)
                .clipShape(Capsule())
        }
        .padding(.horizontal, HORIZONTAL_INSET)
        .padding(.bottom, 1)
    }
    
    // MARK: View Builders

    private var label: some View {
        HStack(
            spacing: Layout.DEFAULT_ADORNMENT_SPACING
                * CalendarWeekRowView.TEXT_SCALE
        ) {
            if item.isCompleted {
                Image(systemName: "checkmark")
                    .font(
                        .system(
                            size: Layout.TEXT * CalendarWeekRowView.TEXT_SCALE
                        )
                    )
            }

            if let contactPhoto, !segment.isContinuation {
                Image(uiImage: contactPhoto)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: CONTACT_PHOTO_SIZE,
                        height: CONTACT_PHOTO_SIZE
                    )
                    .clipShape(Circle())

                Value(
                    item.title,
                    color: .label,
                    scale: CalendarWeekRowView.TEXT_SCALE
                )
                .lineLimit(1)
            } else {
                AdornedValue(
                    item.title,
                    iconConfig: iconConfig,
                    lineLimit: 1,
                    color: .label,
                    scale: CalendarWeekRowView.TEXT_SCALE
                )
            }
        }
        .fixedSize()
    }
}
