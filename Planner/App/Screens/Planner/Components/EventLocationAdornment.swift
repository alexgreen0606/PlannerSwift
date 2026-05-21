//
//  EventLocationAdornment.swift
//  Planner
//
//  Created by Alex Green on 2/27/26.
//

import SwiftUI

struct EventLocationAdornmentView: View {
    let iconConfig: IconConfig
    let locationLabel: String?
    let timeLabel: String?
    let openEventSheet: () -> Void

    // MARK: - Body

    var body: some View {
        if locationLabel != nil || timeLabel != nil {
            HStack {
                if let locationLabel {
                    HStack(spacing: 4) {
                        Image(systemName: iconConfig.name)
                            .foregroundStyle(
                                iconConfig.primaryColor,
                                iconConfig.secondaryColor
                            )

                        Text(locationLabel)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if let timeLabel {
                    Text(timeLabel)
                        .foregroundColor(.secondary)
                }
            }
            .font(.system(size: 10))
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture(perform: openEventSheet)
        }
    }
}
