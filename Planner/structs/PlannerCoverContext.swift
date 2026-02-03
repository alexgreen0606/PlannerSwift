//
//  PlannerCoverContext.swift
//  Planner
//
//  Created by Alex Green on 2/3/26.
//

struct PlannerCoverContext: Identifiable {
    var datestamp: String
    var customSource: String?

    var id: String {
        "\(datestamp)-\(customSource ?? "")"
    }
}
