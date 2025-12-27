//
//  View.swift
//  Planner
//
//  Created by Alex Green on 12/26/25.
//

import SwiftUI

extension View {
    func horizontalEdgeFade(
        leading: CGFloat = 24,
        trailing: CGFloat = 24
    ) -> some View {
        self.mask {
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [.clear, .black],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: leading)

                Rectangle()
                    .fill(Color.black)

                LinearGradient(
                    colors: [.black, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: trailing)
            }
        }
    }
}
