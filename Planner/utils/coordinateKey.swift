//
//  coordinateKey.swift
//  Planner
//
//  Created by Alex Green on 2/13/26.
//

func coordinateKey(lat: Double, long: Double) -> String {
    "\(lat.roundDecimals(to: 4)),\(long.roundDecimals(to: 4))"
}
