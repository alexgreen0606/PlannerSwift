//
//  Duration.swift
//  Planner
//
//  Created by Alex Green on 1/11/26.
//

extension Duration {
    var seconds: Double {
        let c = components
        return Double(c.seconds) + Double(c.attoseconds)
            / 1_000_000_000_000_000_000
    }
}
