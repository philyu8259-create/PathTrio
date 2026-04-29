import XCTest

final class LocalizationTests: XCTestCase {
    func testCoreInterfaceKeysExistInEnglishAndSimplifiedChinese() throws {
        let keys = [
            "app.name",
            "app.subtitle",
            "workout.walk",
            "workout.run",
            "workout.ride",
            "action.start",
            "action.done",
            "settings.title",
            "settings.recording.recordWhenLocked",
            "history.empty.title",
            "detail.started",
            "detail.ended",
            "metric.calories",
            "location.status.permissionBlocked.title",
            "location.status.weakSignal.title",
            "location.status.background.title",
            "location.status.backgroundPermission.title",
            "settings.recording.backgroundDescription",
            "summary.title",
            "smartAssist.autoPause.title"
        ]

        try assertLocalized(keys: keys, table: nil, locale: "en")
        try assertLocalized(keys: keys, table: nil, locale: "zh-Hans")
    }

    func testPermissionPurposeStringsExistInEnglishAndSimplifiedChinese() throws {
        let keys = [
            "CFBundleDisplayName",
            "NSLocationWhenInUseUsageDescription",
            "NSLocationAlwaysAndWhenInUseUsageDescription",
            "NSMotionUsageDescription"
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
