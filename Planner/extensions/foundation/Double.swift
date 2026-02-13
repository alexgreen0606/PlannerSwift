//
//  Double.swift
//  Planner
//
//  Created by Alex Green on 2/13/26.
//

import SwiftUI

extension Double {

    func roundDecimals(to precision: Int = 4) -> Double {
        let factor = pow(10.0, Double(precision))
        return (self * factor).rounded() / factor
    }

}
