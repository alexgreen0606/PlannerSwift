//
//  ScrollViewProxy.swift
//  Planner
//
//  Created by Alex Green on 1/1/26.
//

import SwiftUI

extension ScrollViewProxy {
    func slideTo(
        _ id: some Hashable,
        at anchor: UnitPoint,
        withDelay delay: DispatchTimeInterval = .seconds(0)
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.linear(duration: 3)) {
                self.scrollTo(id, anchor: anchor)
            }
        }
    }
}
