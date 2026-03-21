//
//  ToggleTransitionForm.swift
//  Planner
//
//  Created by Alex Green on 3/20/26.
//

import SwiftUI

// Clean

struct ToggleTransitionFormView: View {

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @AppStorage("toggleTransitionDuration") private
        var toggleTransitionDuration: ToggleTransitionDuration =
            ToggleTransitionDuration.threeSeconds

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
                    "Controls the transition of toggled items. If the destination list is hidden, items fade out over this duration; otherwise, they move to the list after this delay."
                )
            }
        }
        .navigationTitle(ToggleTransitionDuration.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - View Builders

    @ViewBuilder
    private func row(for transitionDuration: ToggleTransitionDuration)
        -> some View
    {
        let isActive = transitionDuration == toggleTransitionDuration
        HStack {

            Text(transitionDuration.label)

            Spacer()
            
            if isActive {
                Image(systemName: "checkmark")
                    .foregroundStyle(accentColor.color)
                    .fontWeight(.semibold)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            toggleTransitionDuration = transitionDuration
        }
    }

}
