import CoreLocation
import MapKit
import SwiftUI

struct RouteMapView: View {
    let locations: [CLLocation]

    private var cameraPosition: MapCameraPosition {
        guard let last = locations.last else {
            return .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
        return .region(MKCoordinateRegion(
            center: last.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        Map(initialPosition: cameraPosition) {
            if locations.count > 1 {
                MapPolyline(coordinates: locations.map(\.coordinate))
                    .stroke(Color.accentColor, lineWidth: 5)
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
}
