//
//  externalData.swift
//  Planner
//
//  Created by Alex Green on 2/7/26.
//

import SwiftUI

// Clean

struct ExternalDataModifier<Key: Equatable>: ViewModifier {
    let key: Key
    let ready: Bool
    let load: () async -> Void

    func body(content: Content) -> some View {
        content
            .task(id: key) {
                await loadIfReady()
            }
            .task(id: ready) {
                await loadIfReady()
            }
    }

    private func loadIfReady() async {
        guard ready else { return }
        await load()
    }
}

extension View {
    func externalData<Key: Equatable>(
        key: Key,
        ready: Bool,
        load: @escaping () async -> Void
    ) -> some View {
        self.modifier(ExternalDataModifier(key: key, ready: ready, load: load))
    }
}
