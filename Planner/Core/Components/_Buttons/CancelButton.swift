//
//  CancelButton.swift
//  Planner
//
//  Created by Alex Green on 5/22/26.
//

import SwiftUI

struct CancelButtonView: View {
    let cancel: () -> Void

    // MARK: - Body

    var body: some View {
        Button(
            "",
            systemImage: "xmark",
            action: cancel
        )
        .tint(Color.label)
    }
}
