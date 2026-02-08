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

    func glassChip(color: Color?, onTap: (() -> Void)?, height: Double? = nil) -> some View {
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
}
