//
//  View.swift
//  Planner
//
//  Created by Alex Green on 12/26/25.
//

import SwiftUI

extension View {

    // Hides list separator and background.
    func discreetListItem() -> some View {
        self
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    // Same style as default section headers.
    func sectionLabel() -> some View {
        self
            .font(.headline)
            .foregroundStyle(Color.secondary)
            .listRowInsets(.bottom, 0)
            .padding(.horizontal)
            .discreetListItem()
    }

    // Pill-shaped, glass chip.
    func glassChip(color: Color? = nil, onTap: (() -> Void)? = nil, height: Double? = nil)
        -> some View
    {
        self
            .padding(.horizontal, (height ?? PlannerLayout.CHIP_HEIGHT) / 3)
            .padding(.vertical, 4)
            .frame(height: height ?? PlannerLayout.CHIP_HEIGHT)
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
                in: .capsule
            )
    }

    // Initiates a scroll whenever the trigger changes.
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

    // Jumpy, fast animation caused by user action (such as a click).
    func animateSynchronousAction<Trigger: Equatable>(from trigger: Trigger)
        -> some View
    {
        self
            .animation(
                .spring(
                    response: 0.4,
                    dampingFraction: 0.4
                ),
                value: trigger
            )
    }

    // Smooth, slick animation caused by asynchronous response (such as weather response).
    func animateAsynchronousAction<Trigger: Equatable>(from trigger: Trigger)
        -> some View
    {
        self
            .animation(
                .spring(
                    response: 1,
                    dampingFraction: 0.4
                ),
                value: trigger
            )
    }

}
