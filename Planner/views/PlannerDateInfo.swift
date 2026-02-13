//
//  PlannerDateInfo.swift
//  Planner
//
//  Created by Alex Green on 1/1/26.
//

import SwiftUI

struct PlannerDateInfoView: View {
    let datestamp: String
    let isSoon: Bool

    private var date: Date? {
        datestamp.date
    }

    private var title: String {
        guard let date else {
            return datestamp
        }
        
        return isSoon ? date.weekday : date.countdown ?? ""
    }

    private var subtitle: String {
        guard let date else {
            return ""
        }
        
        let countdown = date.countdown
        if isSoon, let countdown {
            return countdown
        }

        return date.weekday
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
