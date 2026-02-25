//
//  View.swift
//  Planner
//
//  Created by Alex Green on 12/26/25.
//

import SwiftUI

extension View {

    func discreetListItem() -> some View {
        self
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    func sectionLabel() -> some View {
        self
            .font(.headline)
            .foregroundStyle(Color.secondary)
            .listRowInsets(.bottom, 0)
            .padding(.horizontal)
            .discreetListItem()
    }

    func glassChip(color: Color?, onTap: (() -> Void)?, height: Double? = nil)
        -> some View
    {
        self
            .padding(.horizontal, (height ?? UIConstants.chipHeight) / 3)
            .padding(.vertical, 4)
            .frame(height: height ?? UIConstants.chipHeight)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap?()
            }
            .glassEffect(
                color != nil
                    ? .regular
                        .tint(color!.opacity(0.05))
                        .interactive(onTap != nil)
                    : .regular
                        .interactive(onTap != nil),
                in: .rect(cornerRadius: (height ?? UIConstants.chipHeight) / 2)
            )
    }

    func withScrollTrigger<Trigger: Equatable, ID: Hashable>(
        scrollProxy: ScrollViewProxy,
        trigger: Trigger,
        id: ID?,
        disabled: Bool = false
    ) -> some View {
        self.onChange(of: trigger) { _, _ in
            guard !disabled, let id else { return }

            DispatchQueue.main.async {
                withAnimation {
                    scrollProxy.scrollTo(id, anchor: .top)
                }
            }
        }
    }

    func animateSynchronousAction<Trigger: Equatable>(from trigger: Trigger) -> some View {
        self
            .animation(
                .spring(
                    response: 0.4,
                    dampingFraction: 0.4
                ),
                value: trigger
            )
    }
    
    func animateAsynchronousAction<Trigger: Equatable>(from trigger: Trigger) -> some View {
        self
            .animation(
                .spring(
                    response: 0.9,
                    dampingFraction: 0.4
                ),
                value: trigger
            )
    }

}
