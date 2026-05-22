//
//  TransferSelectedButton.swift
//  Planner
//
//  Created by Alex Green on 5/21/26.
//

import SwiftUI

struct TransferSelectedButtonView<Item: ListItem>: View {
    @Binding var showTransferSheet: Bool
    let systemImage: String
    let disabled: Bool
    let namespace: Namespace.ID

    init(
        showTransferSheet: Binding<Bool>,
        systemImage: String = "arrow.left.arrow.right",
        disabled: Bool = false,
        namespace: Namespace.ID
    ) {
        self._showTransferSheet = showTransferSheet
        self.systemImage = systemImage
        self.disabled = disabled
        self.namespace = namespace
    }

    @EnvironmentObject private var listEngine: ListEngine<Item>

    var body: some View {
        Button(
            "Transfer",
            systemImage: systemImage
        ) {
            showTransferSheet = true
        }
        .disabled(disabled || listEngine.selectedItemIds.isEmpty)
        .matchedTransitionSource(
            id: ListIds.TRANSFER_BUTTON,
            in: namespace
        )
    }
}
