import XCTest
@testable import PathTrio

final class LocalizationTests: XCTestCase {
    func testCoreInterfaceKeysExistInEnglishAndSimplifiedChinese() throws {
        let workoutKeys = WorkoutType.allCases.map { "workout.\($0.rawValue)" }
        let keys = [
            "app.name",
            "app.subtitle",
            "tab.home",
            "tab.history",
            "tab.settings",
            "action.start",
            "action.done",
            "settings.title",
            "settings.recording.recordWhenLocked",
            "settings.health",
            "settings.health.frameworks.title",
            "settings.health.frameworks.healthKit",
            "settings.health.frameworks.privacy",
            "settings.health.syncToAppleHealth",
            "settings.health.healthKitDescription",
            "settings.health.confirm.title",
            "settings.health.confirm.message",
            "settings.health.confirm.enable",
            "health.status.permissionNeeded.title",
            "summary.health.skipped",
            "summary.health.synced",
            "summary.health.unavailable",
            "summary.health.failed",
            "detail.healthSync.synced",
            "detail.healthSync.skipped",
            "detail.healthSync.unavailable",
            "detail.healthSync.failed",
            "detail.healthSync.retry",
            "detail.healthSync.retrying",
            "history.empty.title",
            "detail.started",
            "detail.ended",
            "detail.recording.title",
            "detail.recording.notes",
            "detail.recording.correctedCalories",
            "detail.route.empty.title",
            "detail.route.empty.message",
            "metric.calories",
            "recording.mode.routeTracking",
            "recording.mode.durationOnly",
            "recording.mode.manualEntry",
            "workouts.manual.notes",
            "workouts.manual.notes.hint",
            "location.status.permissionBlocked.title",
            "location.status.weakSignal.title",
            "location.status.background.title",
            "location.status.backgroundPermission.title",
            "settings.recording.backgroundDescription",
            "settings.recording.backgroundConfirm.title",
            "settings.recording.backgroundConfirm.message",
            "settings.recording.backgroundConfirm.enable",
            "pro.title",
            "pro.locked.title",
            "pro.products.title",
            "pro.controls.title",
            "pro.feature.autoRecording.title",
            "pro.feature.dataExport.title",
            "pro.feature.goals.title",
            "map.style.title",
            "goals.title",
            "stats.title",
            "export.history",
            "watch.status.ready.title",
            "pro.feature.appleWatch.title",
            "summary.title",
            "smartAssist.autoPause.title"
        ] + workoutKeys

        try assertLocalized(keys: keys, table: nil, locale: "en")
        try assertLocalized(keys: keys, table: nil, locale: "zh-Hans")
    }

    func testPermissionPurposeStringsExistInEnglishAndSimplifiedChinese() throws {
        let keys = [
            "CFBundleDisplayName",
            "NSLocationWhenInUseUsageDescription",
            "NSLocationAlwaysAndWhenInUseUsageDescription",
            "NSMotionUsageDescription",
            "NSHealthShareUsageDescription",
            "NSHealthUpdateUsageDescription"
        ]

        try assertLocalized(keys: keys, table: "InfoPlist", locale: "en")
        try assertLocalized(keys: keys, table: "InfoPlist", locale: "zh-Hans")
    }

    func testEnglishAndSimplifiedChineseUseTheSameKeys() throws {
        XCTAssertEqual(
            try localizedKeys(table: "Localizable", locale: "en"),
            try localizedKeys(table: "Localizable", locale: "zh-Hans")
        )
        XCTAssertEqual(
            try localizedKeys(table: "InfoPlist", locale: "en"),
            try localizedKeys(table: "InfoPlist", locale: "zh-Hans")
        )
    }

    func testVisibleInsightTitlesDoNotUseAIWording() throws {
        let keys = [
            "insights.title",
            "detail.insights.title"
        ]

        for locale in ["en", "zh-Hans"] {
            let path = try XCTUnwrap(Bundle.main.path(forResource: locale, ofType: "lproj"))
            let bundle = try XCTUnwrap(Bundle(path: path))

            for key in keys {
                let value = bundle.localizedString(forKey: key, value: nil, table: nil)
                XCTAssertFalse(value.localizedCaseInsensitiveContains("AI"), "\(key) still contains AI wording in \(locale)")
            }
        }
    }

    private func assertLocalized(keys: [String], table: String?, locale: String) throws {
        let path = try XCTUnwrap(Bundle.main.path(forResource: locale, ofType: "lproj"))
        let bundle = try XCTUnwrap(Bundle(path: path))

        for key in keys {
            let value = bundle.localizedString(forKey: key, value: nil, table: table)
            XCTAssertNotEqual(value, key, "Missing \(key) in \(locale)")
            XCTAssertFalse(value.isEmpty, "Empty \(key) in \(locale)")
        }
    }

    private func localizedKeys(table: String, locale: String) throws -> Set<String> {
        let path = try XCTUnwrap(Bundle.main.path(forResource: table, ofType: "strings", inDirectory: nil, forLocalization: locale))
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let plist = try XCTUnwrap(try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: String])
        return Set(plist.keys)
    }
}
