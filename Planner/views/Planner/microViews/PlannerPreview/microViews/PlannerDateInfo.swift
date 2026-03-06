//
//  PlannerDateInfo.swift
//  Planner
//
//  Created by Alex Green on 1/1/26.
//

import SwiftUI
import SwiftDate

struct PlannerDateInfoView: View {
    let datestamp: String
    let region: Region
    let isSoon: Bool
    
    private var startOfDay: DateInRegion? {
        datestamp.startOfDay(in: region)
    }

    private var title: String {
        guard let startOfDay else {
            return datestamp
        }
        
        return isSoon ? startOfDay.weekday : startOfDay.countdown
    }

    private var subtitle: String {
        guard let startOfDay else {
            return ""
        }
        
        let countdown = startOfDay.countdown
        if isSoon {
            return countdown
        }

        return startOfDay.weekday
    }

    var body: some View {
        HStack {
            PlannerIcon(datestamp: datestamp, scale: 1.4)
            VStack(alignment: .leading) {
                Text(title)
                    .font(isSoon ? .body : .system(size: 16))
                    .fontWeight(.bold)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
