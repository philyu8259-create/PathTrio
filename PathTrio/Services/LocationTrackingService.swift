import CoreLocation
import Foundation
import Observation

@Observable
final class LocationTrackingService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let locationAcceptancePolicy = LocationAcceptancePolicy()
    private let idleDistanceFilter: CLLocationDistance = 5
    private let activeDistanceFilter: CLLocationDistance = 3
    private var isTrackingRequested = false
    private var isBackgroundTrackingAllowed = false
    private var isPreviewLocationRequested = false
    private var trackingStartedAt: Date?
    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var latestLocations: [CLLocation] = []
    private(set) var latestHorizontalAccuracy: CLLocationAccuracy?
    private(set) var latestErrorMessage: String?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = idleDistanceFilter
        manager.pausesLocationUpdatesAutomatically = true
        manager.allowsBackgroundLocationUpdates = false
        manager.showsBackgroundLocationIndicator = true
    }

    func requestWhenInUsePermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestAlwaysPermission() {
        manager.requestAlwaysAuthorization()
    }

    func preparePreviewLocation() {
        guard !isTrackingRequested else { return }
        latestLocations.removeAll()
        latestHorizontalAccuracy = nil
        latestErrorMessage = nil

        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .notDetermined:
            isPreviewLocationRequested = true
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    func start(backgroundAllowed: Bool) {
        isTrackingRequested = true
        isPreviewLocationRequested = false
        isBackgroundTrackingAllowed = backgroundAllowed
        trackingStartedAt = Date()
        manager.distanceFilter = kCLDistanceFilterNone
        latestLocations.removeAll()
        latestHorizontalAccuracy = nil
        latestErrorMessage = nil
        startUpdatingLocationIfAuthorized()
    }

    func stop() {
        isTrackingRequested = false
        trackingStartedAt = nil
        manager.stopUpdatingLocation()
        manager.distanceFilter = idleDistanceFilter
        manager.allowsBackgroundLocationUpdates = false
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if isPreviewLocationRequested {
            switch authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                isPreviewLocationRequested = false
                manager.requestLocation()
            case .denied, .restricted:
                isPreviewLocationRequested = false
            case .notDetermined:
                break
            @unknown default:
                isPreviewLocationRequested = false
            }
        }
        startUpdatingLocationIfAuthorized()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        latestHorizontalAccuracy = locations.last?.horizontalAccuracy ?? latestHorizontalAccuracy
        let acceptedLocations = locationAcceptancePolicy.acceptedLocations(
            from: locations,
            existingAcceptedCount: latestLocations.count,
            trackingStartedAt: trackingStartedAt,
            now: Date()
        )
        guard !acceptedLocations.isEmpty else { return }

        latestLocations.append(contentsOf: acceptedLocations)
        manager.distanceFilter = activeDistanceFilter
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        latestErrorMessage = error.localizedDescription
    }

    private func startUpdatingLocationIfAuthorized() {
        guard isTrackingRequested else { return }
        switch authorizationStatus {
        case .authorizedAlways:
            manager.allowsBackgroundLocationUpdates = isBackgroundTrackingAllowed
            manager.startUpdatingLocation()
        case .authorizedWhenInUse:
            manager.allowsBackgroundLocationUpdates = false
            manager.startUpdatingLocation()
        case .notDetermined, .denied, .restricted:
            break
        @unknown default:
            break
        }
    }
}

struct LocationAcceptancePolicy {
    var maximumHorizontalAccuracy: CLLocationAccuracy = 65
    var maximumInitialHorizontalAccuracy: CLLocationAccuracy = 35
    var startupStaleTolerance: TimeInterval = 2
    var futureTimestampTolerance: TimeInterval = 5

    func acceptedLocations(
        from locations: [CLLocation],
        existingAcceptedCount: Int,
        trackingStartedAt: Date?,
        now: Date
    ) -> [CLLocation] {
        var hasAcceptedInitialLocation = existingAcceptedCount > 0

        return locations.filter { location in
            guard CLLocationCoordinate2DIsValid(location.coordinate) else { return false }
            guard location.horizontalAccuracy >= 0, location.horizontalAccuracy <= maximumHorizontalAccuracy else { return false }

            if let trackingStartedAt {
                guard location.timestamp >= trackingStartedAt.addingTimeInterval(-startupStaleTolerance) else { return false }
            }
            guard location.timestamp <= now.addingTimeInterval(futureTimestampTolerance) else { return false }

            if !hasAcceptedInitialLocation {
                guard location.horizontalAccuracy <= maximumInitialHorizontalAccuracy else { return false }
            }

            hasAcceptedInitialLocation = true
            return true
        }
    }
}
