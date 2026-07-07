//
//  Month.swift
//  Planner
//
//  Created by Alex Green on 7/6/26.
//

enum Month: String, Codable, CaseIterable, Identifiable {
    case January
    case February
    case March
    case April
    case May
    case June
    case July
    case August
    case September
    case October
    case November
    case December

    var id: String {
        rawValue
    }

    var label: String {
        rawValue
    }

    var number: Int {
        switch self {
        case .January: return 1
        case .February: return 2
        case .March: return 3
        case .April: return 4
        case .May: return 5
        case .June: return 6
        case .July: return 7
        case .August: return 8
        case .September: return 9
        case .October: return 10
        case .November: return 11
        case .December: return 12
        }
    }

    static func from(number: Int) -> Month? {
        Month.allCases.first { $0.number == number }
    }
}
