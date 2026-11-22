//
//  Binding+.swift
//  Planner
//
//  Created by Alex Green on 11/21/26.
//

import SwiftUI

extension Binding {
    func onUpdate(_ closure: @escaping (Value, Value) -> Void) -> Binding<Value>
    {
        Binding(
            get: {
                wrappedValue
            },
            set: { newValue in
                let oldValue = wrappedValue
                closure(oldValue, newValue)
                wrappedValue = newValue
            }
        )
    }
}
