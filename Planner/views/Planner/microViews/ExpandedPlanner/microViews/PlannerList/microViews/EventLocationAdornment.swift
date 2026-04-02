//
//  EventLocationAdornment.swift
//  Planner
//
//  Created by Alex Green on 2/27/26.
//

import SwiftUI

// Clean

struct EventLocationAdornmentView: View {
    let iconConfig: IconConfig
    let locationLabel: String?
    let timeLabel: String?
    let openEventSheet: () -> Void

    var body: some View {
        if locationLabel != nil || timeLabel != nil {
            HStack {

                if let locationLabel {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: iconConfig.name)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 10, height: 10)
                            .foregroundStyle(iconConfig.primaryColor, iconConfig.secondaryColor)

                        Text(locationLabel)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if let timeLabel {
                    Text(timeLabel)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 4)
            .contentShape(Rectangle())
            .onTapGesture(perform: openEventSheet)
        }
    }
}
