//
//  TodayWeatherChipContainer.swift
//  Planner
//
//  Created by Alex Green on 10/2/26.
//

import SwiftUI
import WeatherKit

struct TodayWeatherChipContainerView: View {

    // MARK: - Body

    var body: some View {
        TodayWeatherChipShape()
            .fill(.clear)
            .glassEffect(
                .regular.interactive(),
                in: TodayWeatherChipShape()
            )
            .frame(maxWidth: .infinity)
            .frame(width: 200, height: (PlannerLayout.CHIP_HEIGHT * 2 + 8))
    }
}

// MARK: - Shape

private struct TodayWeatherChipShape: Shape {

    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height

        // MARK: Dimensions

        let smallHeight = PlannerLayout.CHIP_HEIGHT
        let radius = PlannerLayout.CHIP_HEIGHT / 2

        let transitionX = width - height
        let bottom = height

        var path = Path()

        // MARK: Top-left corner

        path.move(
            to: CGPoint(
                x: radius,
                y: 0
            )
        )

        path.addArc(
            center: CGPoint(
                x: radius,
                y: radius
            ),
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(180),
            clockwise: true
        )

        // MARK: Left edge

        path.addLine(
            to: CGPoint(
                x: 0,
                y: smallHeight - radius
            )
        )

        // MARK: Bottom-left corner of smaller section

        path.addArc(
            center: CGPoint(
                x: radius,
                y: smallHeight - radius
            ),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(90),
            clockwise: true
        )
        
        // Bottom edge of smaller section
        path.addLine(
            to: CGPoint(
                x: transitionX,
                y: smallHeight
            )
        )

        // Concave curve into taller section
        path.addCurve(
            to: CGPoint(
                x: transitionX + radius,
                y: smallHeight + radius
            ),
            control1: CGPoint(
                x: transitionX + radius,
                y: smallHeight
            ),
            control2: CGPoint(
                x: transitionX + radius,
                y: smallHeight + radius
            )
        )

        // Left edge of taller section
        path.addLine(
            to: CGPoint(
                x: transitionX + radius,
                y: bottom - radius
            )
        )

        // MARK: Bottom-left corner of taller section

        path.addArc(
            center: CGPoint(
                x: transitionX + (radius * 2),
                y: bottom - radius
            ),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(90),
            clockwise: true
        )

        // MARK: Bottom edge of taller section

        path.addLine(
            to: CGPoint(
                x: width - radius,
                y: bottom
            )
        )

        // MARK: Bottom-right corner

        path.addArc(
            center: CGPoint(
                x: width - radius,
                y: bottom - radius
            ),
            radius: radius,
            startAngle: .degrees(90),
            endAngle: .degrees(0),
            clockwise: true
        )

        // MARK: Right edge

        path.addLine(
            to: CGPoint(
                x: width,
                y: radius
            )
        )

        // MARK: Top-right corner

        path.addArc(
            center: CGPoint(
                x: width - radius,
                y: radius
            ),
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(-90),
            clockwise: true
        )

        // MARK: Top edge

        path.addLine(
            to: CGPoint(
                x: radius,
                y: 0
            )
        )

        path.closeSubpath()

        return path
    }
}
