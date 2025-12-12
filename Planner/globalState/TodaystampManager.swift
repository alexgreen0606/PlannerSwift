//
//  TodaystampManager.swift
//  Planner
//
//  Created by Alex Green on 12/5/25.
//

import Foundation
import SwiftDate
import Combine

@MainActor
class TodaystampManager: ObservableObject {
    @Published private(set) var todaystamp: String = TodaystampManager.makeStamp()

    private var timer: Timer?

    init() {
        scheduleMidnightUpdate()
    }
    
    private static func makeStamp() -> String {
        DateInRegion(region: .current).toFormat("yyyy-MM-dd", locale: Locale.current)
    }

    private func scheduleMidnightUpdate() {
        timer?.invalidate()

        let now = DateInRegion(region: .current)
        let nextMidnight = now.dateAt(.tomorrowAtStart)
        
        timer = Timer(
            fireAt: nextMidnight.date,
            interval: 0,
            target: self,
            selector: #selector(updateStamp),
            userInfo: nil,
            repeats: false
        )

        RunLoop.main.add(timer!, forMode: .common)
    }

    @objc private func updateStamp() {
        todaystamp = Self.makeStamp()
        scheduleMidnightUpdate() // reschedule for tomorrow
    }
}
