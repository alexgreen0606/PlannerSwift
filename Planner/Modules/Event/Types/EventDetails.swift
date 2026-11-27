//
//  EventDetails.swift
//  Planner
//
//  Created by Alex Green on 6/19/26.
//

import Foundation

protocol EventDetails: ListItemDetails {
    var time: Date? { get set }
}
