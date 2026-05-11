import CoreLocation
import Foundation

enum MapDisplayCoordinateTransformer {
    static func displayCoordinate(for coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard shouldApplyMainlandChinaOffset(to: coordinate) else {
            return coordinate
        }

        return wgs84ToGcj02(coordinate)
    }

    static func shouldApplyMainlandChinaOffset(to coordinate: CLLocationCoordinate2D) -> Bool {
        guard CLLocationCoordinate2DIsValid(coordinate) else { return false }
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude

        guard latitude >= 0.8293, latitude <= 55.8271, longitude >= 72.004, longitude <= 137.8347 else {
            return false
        }

        // Hong Kong, Macau, and Taiwan should keep raw WGS-84 display coordinates.
        if latitude >= 22.10, latitude <= 22.60, longitude >= 113.80, longitude <= 114.40 {
            return false
        }
        if latitude >= 21.90, latitude <= 22.30, longitude >= 113.45, longitude <= 113.65 {
            return false
        }
        if latitude >= 21.80, latitude <= 25.40, longitude >= 119.30, longitude <= 122.10 {
            return false
        }

        return true
    }

    private static func wgs84ToGcj02(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let a = 6_378_245.0
        let ee = 0.00669342162296594323
        let x = coordinate.longitude - 105.0
        let y = coordinate.latitude - 35.0
        var latitudeDelta = transformLatitude(x: x, y: y)
        var longitudeDelta = transformLongitude(x: x, y: y)
        let radLatitude = coordinate.latitude / 180.0 * Double.pi
        var magic = sin(radLatitude)
        magic = 1 - ee * magic * magic
        let sqrtMagic = sqrt(magic)
        latitudeDelta = (latitudeDelta * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * Double.pi)
        longitudeDelta = (longitudeDelta * 180.0) / (a / sqrtMagic * cos(radLatitude) * Double.pi)
        return CLLocationCoordinate2D(
            latitude: coordinate.latitude + latitudeDelta,
            longitude: coordinate.longitude + longitudeDelta
        )
    }

    private static func transformLatitude(x: Double, y: Double) -> Double {
        var result = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x))
        result += (20.0 * sin(6.0 * x * Double.pi) + 20.0 * sin(2.0 * x * Double.pi)) * 2.0 / 3.0
        result += (20.0 * sin(y * Double.pi) + 40.0 * sin(y / 3.0 * Double.pi)) * 2.0 / 3.0
        result += (160.0 * sin(y / 12.0 * Double.pi) + 320 * sin(y * Double.pi / 30.0)) * 2.0 / 3.0
        return result
    }

    private static func transformLongitude(x: Double, y: Double) -> Double {
        var result = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x))
        result += (20.0 * sin(6.0 * x * Double.pi) + 20.0 * sin(2.0 * x * Double.pi)) * 2.0 / 3.0
        result += (20.0 * sin(x * Double.pi) + 40.0 * sin(x / 3.0 * Double.pi)) * 2.0 / 3.0
        result += (150.0 * sin(x / 12.0 * Double.pi) + 300.0 * sin(x / 30.0 * Double.pi)) * 2.0 / 3.0
        return result
    }
}
