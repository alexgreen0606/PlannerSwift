//
//  KeepCanceledEventsForm.swift
//  Planner
//
//  Created by Alex Green on 3/20/26.
//

import SwiftUI

// Clean

struct KeepCanceledEventsFormView: View {

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @AppStorage("keepCanceledEventsDuration") private
        var keepCanceledEventsDuration: KeepCanceledEventsDuration =
            KeepCanceledEventsDuration.startOfDay

    var body: some View {
        List {
            Section {
                ForEach(
                    KeepCanceledEventsDuration.allCases,
                    id: \.self,
                    content: row
                )
            } footer: {
                Text(
                    "Controls how long to keep canceled plans. Forever means they remain until they expire (see ‘Keep Past Events’ for expiration details)."
                )
            }
        }
        .navigationTitle(KeepCanceledEventsDuration.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - View Builders

    @ViewBuilder
    private func row(for duration: KeepCanceledEventsDuration)
        -> some View
    {
        let isActive = duration == keepCanceledEventsDuration
        HStack {

            Text(duration.label)

            Spacer()

            if isActive {
                Image(systemName: "checkmark")
                    .foregroundStyle(accentColor.color)
                    .fontWeight(.semibold)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            keepCanceledEventsDuration = duration
        }
    }

}
