//
//  Optional+.swift
//  Planner
//
//  Created by Alex Green on 6/19/26.
//

extension Optional where Wrapped: RangeReplaceableCollection {
    mutating func safeAppend(_ element: Wrapped.Element) {
        if self == nil {
            self = .init()
        }
        self?.append(element)
    }
}
