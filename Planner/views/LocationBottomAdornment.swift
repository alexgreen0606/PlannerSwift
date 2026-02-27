//
//  LocationBottomAdornment.swift
//  Planner
//
//  Created by Alex Green on 2/27/26.
//

import SwiftUI

struct LocationBottomAdornmentView: View {
    let icon: IconConfig
    let locationText: String?
    let timeText: String?
    let openEventSheet: () -> Void

    var body: some View {
        if locationText != nil || timeText != nil {
            HStack {
                
                if let locationText {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: icon.name)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 10, height: 10)
                            .foregroundStyle(icon.primaryColor, icon.secondaryColor)
                        
                        Text(locationText)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let timeText {
                    Text(timeText)
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
