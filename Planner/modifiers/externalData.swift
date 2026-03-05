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
                guard ready else { return }
                await load()
            }
            .onChange(of: key) { _, _ in
                guard ready else { return }
                Task { await load() }
            }
            .onChange(of: ready) { _, ready in
                guard ready else { return }
                Task { await load() }
            }
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
