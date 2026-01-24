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
    ) {
        withAnimation(.linear(duration: 0.5)) {
            self.scrollTo(id, anchor: anchor)
        }
    }
}
