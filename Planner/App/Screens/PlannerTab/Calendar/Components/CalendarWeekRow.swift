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
    static let ITEM_AREA_VERTICAL_PADDING: CGFloat = 4
    /// Fixed scale for all calendar text. Font sizes are set explicitly, so they ignore Dynamic Type.
    static let TEXT_SCALE = 0.7
    static let TEXT_SIZE = Layout.TEXT * TEXT_SCALE
    static let TEXT_WEIGHT: Font.Weight = .medium
    static let TEXT_DESIGN: Font.Design = .rounded
    static let SEGMENT_UNDERLINE_HEIGHT: CGFloat = 1
    static let SEGMENT_BOTTOM_PADDING: CGFloat = 2
    /// Fits one line of calendar text plus the segment's underline and bottom padding.
    static let LANE_HEIGHT: CGFloat = ceil(
        UIFont.systemFont(ofSize: TEXT_SIZE).lineHeight
            + SEGMENT_UNDERLINE_HEIGHT
            + SEGMENT_BOTTOM_PADDING
    )

    /// How many lanes fit in a row of the given height. One lane height is always reserved for
    /// the remaining count, and partial lanes are rounded down.
    static func laneCount(forRowHeight rowHeight: CGFloat) -> Int {
        let fittingLanes = Int(
            (itemAreaHeight(forRowHeight: rowHeight) / LANE_HEIGHT)
                .rounded(.down)
        )
        return max(0, fittingLanes - 1)
    }

    /// Height of the item area (lanes + remaining count), inset by its vertical padding.
    static func itemAreaHeight(forRowHeight rowHeight: CGFloat) -> CGFloat {
        max(
            0,
            rowHeight - VERTICAL_PADDING * 2 - DAY_NUMBER_HEIGHT
                - ITEM_AREA_VERTICAL_PADDING * 2
        )
    }

    /// The height inside each cell's vertical padding.
    private var contentHeight: CGFloat {
        max(0, height - Self.VERTICAL_PADDING * 2)
    }

    private var laneCount: Int {
        Self.laneCount(forRowHeight: height)
    }

    /// Top of the item area, measured from the top of the row.
    private var itemAreaTop: CGFloat {
        Self.VERTICAL_PADDING + Self.DAY_NUMBER_HEIGHT
            + Self.ITEM_AREA_VERTICAL_PADDING
    }

    private var itemAreaHeight: CGFloat {
        Self.itemAreaHeight(forRowHeight: height)
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
                    // Note: Sits in the lane reserved just below the visible lanes.
                    Text("+\(count)")
                        .font(.system(size: Self.TEXT_SIZE))
                        .foregroundStyle(Color.secondary)
                        .frame(width: columnWidth, height: Self.LANE_HEIGHT)
                        .offset(
                            x: columnWidth * CGFloat(column),
                            y: Self.LANE_HEIGHT * CGFloat(laneCount)
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

    private var digitColor: Color {
        if isToday { return Color.inverseLabel }
        return datestamp.isWeekend ? Color.secondary : Color.label
    }
    
    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            Text(String(datestamp.dayDigit ?? 0))
                .fontWeight(.black)
                .fontDesign(.rounded)
                .foregroundStyle(digitColor)
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

    private let HORIZONTAL_INSET: CGFloat = 2
    /// Fraction of a single day's width used to fade out the title (matches the old 0.7 → 1 mask).
    private let FADE_FRACTION_OF_DAY = 0.15

    /// Where the fade begins, so it always covers the last 30% of the final day.
    private var fadeStart: Double {
        1 - FADE_FRACTION_OF_DAY / Double(max(1, segment.span))
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    private var item: CalendarItem {
        segment.item
    }

    /// Matches the calendar text size so it fits within a lane alongside the underline.
    private let CONTACT_PHOTO_SIZE = CalendarWeekRowView.TEXT_SIZE

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
                .frame(height: CalendarWeekRowView.SEGMENT_UNDERLINE_HEIGHT)
                .clipShape(Capsule())
        }
        .padding(.horizontal, HORIZONTAL_INSET)
        .padding(.bottom, CalendarWeekRowView.SEGMENT_BOTTOM_PADDING)
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
                            size: CalendarWeekRowView.TEXT_SIZE,
                            weight: CalendarWeekRowView.TEXT_WEIGHT,
                            design: CalendarWeekRowView.TEXT_DESIGN
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
                    scale: CalendarWeekRowView.TEXT_SCALE,
                    weight: CalendarWeekRowView.TEXT_WEIGHT,
                    design: CalendarWeekRowView.TEXT_DESIGN
                )
                .lineLimit(1)
            } else {
                AdornedValue(
                    item.title,
                    iconConfig: iconConfig,
                    lineLimit: 1,
                    color: .label,
                    scale: CalendarWeekRowView.TEXT_SCALE,
                    weight: CalendarWeekRowView.TEXT_WEIGHT,
                    design: CalendarWeekRowView.TEXT_DESIGN
                )
            }
        }
        .fixedSize()
    }
}
