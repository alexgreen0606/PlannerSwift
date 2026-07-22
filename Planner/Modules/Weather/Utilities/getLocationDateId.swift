//
//  getLocationDateId.swift
//  Planner
//
//  Created by Alex Green on 7/17/26.
//

import Foundation

func getLocationDateId(coordinateId: String, startOfDay: Date) -> String {
    "\(coordinateId)_\(startOfDay)"
}
