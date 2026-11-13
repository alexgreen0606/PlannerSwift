//
//  StructuredDatestampsContext.swift
//  Planner
//
//  Created by Alex Green on 11/10/26.
//

struct StructuredDatestampsContext {
    let datestamps: [String]
    private let reversed: Bool

    init(datestamps: [String], reversed: Bool = false) {
        self.datestamps = datestamps
        self.reversed = reversed
    }

    var sorted: [String] {
        datestamps.sorted {
            reversed
                ? $0 > $1
                : $0 < $1
        }
    }
    
    var topDatestamp: String? {
        sorted.first
    }

    var sortedByYear: [String: [String]] {
        Dictionary(grouping: sorted) {
            $0.year
        }
    }

    var sortedYears: [String] {
        sortedByYear.keys.sorted {
            reversed
                ? $0 > $1
                : $0 < $1
        }
    }
}
