//
//  ProgressBar.swift
//  Planner
//
//  Created by Alex Green on 10/5/26.
//

import SwiftUI

struct ProgressBarView: View {
    private let width: CGFloat
    private let progress: CGFloat
    private let color: Color?
    private let progressColor: Color?

    init(
        width: CGFloat,
        progress: CGFloat,
        color: Color? = nil,
        progressColor: Color? = nil
    ) {
        self.width = width
        self.progress = progress
        self.color = color
        self.progressColor = progressColor
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(color ?? Color.secondary.opacity(0.15))
                .frame(width: width)

            Capsule()
                .fill(progressColor ?? accentColor.swiftUiColor)
                .frame(width: width * progress)
        }
        .frame(height: 8)
    }
}
