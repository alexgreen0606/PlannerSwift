//
//  KeepPastEventsForm.swift
//  Planner
//
//  Created by Alex Green on 3/20/26.
//

import SwiftUI

// Clean

struct KeepPastEventsFormView: View {

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @AppStorage("keepPastEventsDuration") private var keepPastEventsDuration:
        KeepPastEventsDuration =
            KeepPastEventsDuration.oneMonth

    var body: some View {
        List {
            Section {
                ForEach(
                    KeepPastEventsDuration.allCases,
                    id: \.self,
                    content: row
                )
            } footer: {
                Text(
                    "Controls how long past plans are kept. Keeping them forever will increase storage usage over time."
                )
            }
        }
        .navigationTitle(KeepPastEventsDuration.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - View Builders

    @ViewBuilder
    private func row(for pastPlansDuration: KeepPastEventsDuration)
        -> some View
    {
        let isActive = pastPlansDuration == keepPastEventsDuration
        HStack {

            Text(pastPlansDuration.label)

            Spacer()

            if isActive {
                Image(systemName: "checkmark")
                    .foregroundStyle(accentColor.color)
                    .fontWeight(.semibold)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            keepPastEventsDuration = pastPlansDuration
        }
    }

}
