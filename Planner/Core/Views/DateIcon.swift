////
////  DateIcon.swift
////  Planner
////
////  Created by Alex Green on 12/21/25.
////

import SwiftUI

struct DateIconView: View {
    let iconConfig: IconConfig
    let size: CGFloat
    let detail: String
    let detailSize: CGFloat
    let detailColor: Color
    let detailOffset: CGFloat

    var body: some View {
        ZStack(alignment: .top) {
            Icon(iconConfig)
                .font(.system(size: size))

            Text(detail)
                .font(
                    .system(
                        size: detailSize,
                        weight: .black,
                        design: .rounded
                    )
                )
                .foregroundStyle(detailColor)
                .offset(y: detailOffset)
        }
    }
}
