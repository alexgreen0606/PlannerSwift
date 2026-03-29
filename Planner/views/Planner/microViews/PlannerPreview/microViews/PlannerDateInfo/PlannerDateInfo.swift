//
//  PlannerDateInfo.swift
//  Planner
//
//  Created by Alex Green on 1/1/26.
//

import SwiftDate
import SwiftUI

// Clean

struct PlannerDateInfoView: View {
    let datestamp: String
    let title: String
    let subtitle: String

    var body: some View {
        
        PlannerIconView(datestamp: datestamp, scale: 1.4)
        
        VStack(alignment: .leading) {
            Text(title)
                .fontWeight(.bold)
                .fontDesign(.rounded)

            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        
    }
}
