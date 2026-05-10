import Foundation

enum PathTrioMapStyle: String, CaseIterable, Identifiable {
    case standard
    case hybrid
    case imagery

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .standard: "map.style.standard"
        case .hybrid: "map.style.hybrid"
        case .imagery: "map.style.imagery"
        }
    }
}
