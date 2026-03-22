//
//  TripExtension.swift
//  Planner
//
//  Created by Alex Green on 3/22/26.
//

// Clean

extension Trip {
    
    func plannerTransitionId(for datestamp: String) -> String {
        "\(datestamp)_\(String(describing: id))"
    }
    
}
