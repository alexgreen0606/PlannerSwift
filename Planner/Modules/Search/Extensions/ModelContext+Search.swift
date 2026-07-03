//
//  ModelContext+Search.swift
//  Planner
//
//  Created by Alex Green on 7/1/26.
//

import Fuse
import SwiftData

extension ModelContext {
    func defaultSearchQuery(
        todaystamp: String,
        settings: Settings
    ) -> SearchQuery {
        let todayPlanner = getPlanner(
            for: todaystamp
        )

        return SearchQuery(
            text: "",
            calendarIds: [],
            past: false,
            todayStartOfDay: todayPlanner.startOfDay(settings: settings),
            fuse: Fuse()
        )
    }
}
