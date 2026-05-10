import Foundation

enum ProFeature: String, CaseIterable, Identifiable {
    case autoRecording
    case advancedStats
    case trendReview
    case dataExport
    case goals
    case mapStyles
    case advancedHealthSync
    case appleWatch

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .autoRecording: "pro.feature.autoRecording.title"
        case .advancedStats: "pro.feature.advancedStats.title"
        case .trendReview: "pro.feature.trendReview.title"
        case .dataExport: "pro.feature.dataExport.title"
        case .goals: "pro.feature.goals.title"
        case .mapStyles: "pro.feature.mapStyles.title"
        case .advancedHealthSync: "pro.feature.advancedHealthSync.title"
        case .appleWatch: "pro.feature.appleWatch.title"
        }
    }

    var messageKey: String {
        switch self {
        case .autoRecording: "pro.feature.autoRecording.message"
        case .advancedStats: "pro.feature.advancedStats.message"
        case .trendReview: "pro.feature.trendReview.message"
        case .dataExport: "pro.feature.dataExport.message"
        case .goals: "pro.feature.goals.message"
        case .mapStyles: "pro.feature.mapStyles.message"
        case .advancedHealthSync: "pro.feature.advancedHealthSync.message"
        case .appleWatch: "pro.feature.appleWatch.message"
        }
    }

    var systemImage: String {
        switch self {
        case .autoRecording: "figure.walk.motion"
        case .advancedStats: "chart.bar.xaxis"
        case .trendReview: "chart.line.uptrend.xyaxis"
        case .dataExport: "square.and.arrow.up"
        case .goals: "target"
        case .mapStyles: "map"
        case .advancedHealthSync: "heart.text.square"
        case .appleWatch: "applewatch"
        }
    }
}
