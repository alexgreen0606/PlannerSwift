//
//  ToggleTransitionForm.swift
//  Planner
//
//  Created by Alex Green on 3/20/26.
//

import SwiftUI

struct ToggleTransitionFormView: View {
    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @AppStorage("toggleTransitionDuration") private
        var toggleTransitionDuration: ToggleTransitionDuration =
            .threeSeconds

    // MARK: - Body

    var body: some View {
        List {
            Section {
                ForEach(
                    ToggleTransitionDuration.allCases,
                    id: \.self,
                    content: row
                )
            } footer: {
                Text(
                    "If the destination list is hidden, items fade out over this duration; otherwise, they jump to the list after this delay."
                )
            }
        }
        .navigationTitle(ToggleTransitionDuration.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - View Builders

    private func row(for transitionDuration: ToggleTransitionDuration)
        -> some View
    {
        HStack {
            Text(transitionDuration.label)
                .frame(maxWidth: .infinity, alignment: .leading)

            if transitionDuration == toggleTransitionDuration {
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
                    .foregroundStyle(accentColor.color)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            toggleTransitionDuration = transitionDuration
        }
    }
}
