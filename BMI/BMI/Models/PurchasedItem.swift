import Foundation

enum PurchasedItem: String, Codable, CaseIterable, Identifiable {
    case bigMac
    case bigMacMeal
    case doubleBigMac
    case mcDouble
    case quarterPounder
    case mcChicken
    case mcNuggets
    case fries
    case drink
    case shake
    case applePie
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bigMac: "Big Mac"
        case .bigMacMeal: "Big Mac Meal"
        case .doubleBigMac: "Double Big Mac"
        case .mcDouble: "McDouble"
        case .quarterPounder: "Quarter Pounder"
        case .mcChicken: "McChicken"
        case .mcNuggets: "McNuggets"
        case .fries: "Fries"
        case .drink: "Drink"
        case .shake: "Shake"
        case .applePie: "Apple Pie"
        case .other: "Other"
        }
    }

    var isBigMacVariant: Bool {
        switch self {
        case .bigMac, .bigMacMeal, .doubleBigMac: true
        default: false
        }
    }
}
