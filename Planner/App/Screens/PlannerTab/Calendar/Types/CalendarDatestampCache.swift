//
//  CalendarDatestampCache.swift
//  Planner
//
//  Created by Alex Green on 11/18/26.
//

import SwiftUI

@MainActor
final class CalendarDatestampCache {
    static let shared = CalendarDatestampCache()

    private var referenceMonthstamp: String?
    private var monthstamps: [Int: String] = [:]
    private var datestamps: [String: [String?]] = [:]

    private init() {}

    func update(currentMonthstamp: String) {
        guard currentMonthstamp != referenceMonthstamp else { return }

        referenceMonthstamp = currentMonthstamp
        monthstamps.removeAll()
    }

    func monthstamp(for offset: Int) -> String {
        guard let referenceMonthstamp else {
            assertionFailure("CalendarDateCache has not been initialized.")
            return ""
        }

        if let cached = monthstamps[offset] {
            return cached
        }

        let stamp =
            DatestampFormatter.monthstamp(
                from: referenceMonthstamp,
                offset: offset
            ) ?? ""

        monthstamps[offset] = stamp
        return stamp
    }

    func datestamps(forMonthstamp monthstamp: String) -> [String?] {
        if let cached = datestamps[monthstamp] {
            return cached
        }

        let computed = DatestampFormatter.datestamps(
            for: monthstamp
        )

        datestamps[monthstamp] = computed
        return computed
    }
}
