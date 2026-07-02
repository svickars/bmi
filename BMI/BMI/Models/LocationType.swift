import Foundation

enum LocationType: String, Codable, CaseIterable, Identifiable {
    case urban
    case suburban
    case rural
    case highway
    case airport
    case mall
    case downtown
    case tourist
    case trainStation
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .urban: "Urban"
        case .suburban: "Suburban"
        case .rural: "Rural"
        case .highway: "Highway Rest Stop"
        case .airport: "Airport"
        case .mall: "Shopping Mall"
        case .downtown: "Downtown"
        case .tourist: "Tourist Area"
        case .trainStation: "Train Station"
        case .other: "Other"
        }
    }

    var icon: String {
        switch self {
        case .urban: "building.2.fill"
        case .suburban: "house.fill"
        case .rural: "leaf.fill"
        case .highway: "car.fill"
        case .airport: "airplane"
        case .mall: "bag.fill"
        case .downtown: "building.columns.fill"
        case .tourist: "camera.fill"
        case .trainStation: "tram.fill"
        case .other: "mappin.and.ellipse"
        }
    }
}
