//
//  TransferSelectedButton.swift
//  Planner
//
//  Created by Alex Green on 5/21/26.
//

import SwiftUI

struct TransferSelectedButtonView<Item: ListItemDetails>: View {
    @Binding private var showTransferSheet: Bool
    private let systemImage: String
    private let disabled: Bool
    private let namespace: Namespace.ID

    init(
        showTransferSheet: Binding<Bool>,
        systemImage: String = "arrow.left.arrow.right",
        disabled: Bool = false,
        namespace: Namespace.ID
    ) {
        _showTransferSheet = showTransferSheet
        self.systemImage = systemImage
        self.disabled = disabled
        self.namespace = namespace
    }

    @EnvironmentObject private var listEngine: ListEngine<Item>

    // MARK: - Body

    var body: some View {
        GlassIconButtonView(systemImageName: systemImage) {
            showTransferSheet = true
        }
        .disabled(disabled || listEngine.selectedItemIds.isEmpty)
        .matchedTransitionSource(
            id: ListIds.TRANSFER_BUTTON,
            in: namespace
        )
    }
}
