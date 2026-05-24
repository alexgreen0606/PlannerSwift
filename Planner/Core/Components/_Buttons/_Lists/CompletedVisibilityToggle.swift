//
//  CompletedVisibilityToggle.swift
//  Planner
//
//  Created by Alex Green on 5/22/26.
//

import SwiftUI

struct CompletedVisibilityToggleView: View {
    let showCompleted: Bool
    let toggle: () -> Void

    // MARK: - Body

    var body: some View {
        Button {
            toggle()
        } label: {
            Label(
                showCompleted
                    ? "Hide Completed"
                    : "Show Completed",
                systemImage: showCompleted
                    ? "eye.slash" : "eye"
            )
        }
    }
}
