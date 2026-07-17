//
//  KeepPastEventsForm.swift
//  Planner
//
//  Created by Alex Green on 3/20/26.
//

import SwiftUI

struct KeepPastEventsFormView: View {
    let settings: Settings
    
    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    // MARK: - Body

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
                    "Keeping events forever will increase storage usage over time."
                )
            }
        }
        .navigationTitle(KeepPastEventsDuration.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - View Builders

    private func row(for pastPlansDuration: KeepPastEventsDuration)
        -> some View
    {
        HStack {
            Text(pastPlansDuration.label)
                .frame(maxWidth: .infinity, alignment: .leading)

            if pastPlansDuration == settings.keepPastEventsDuration {
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
                    .foregroundStyle(accentColor.swiftUiColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            settings.keepPastEventsDuration = pastPlansDuration
        }
    }
}
