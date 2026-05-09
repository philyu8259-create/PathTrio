import CoreLocation
import MapKit
import SwiftUI

struct RouteMapView: View {
    let locations: [CLLocation]
    var followsLatestLocation = false

    @State private var cameraPosition: MapCameraPosition = .automatic

    private var targetCameraPosition: MapCameraPosition {
        guard let first = locations.first else {
            return .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }

        if followsLatestLocation, let latest = locations.last {
            return .region(MKCoordinateRegion(
                center: latest.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            ))
        }

        guard locations.count > 1 else {
            return .region(MKCoordinateRegion(
                center: first.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }

        let latitudes = locations.map(\.coordinate.latitude)
        let longitudes = locations.map(\.coordinate.longitude)
        let minLatitude = latitudes.min() ?? first.coordinate.latitude
        let maxLatitude = latitudes.max() ?? first.coordinate.latitude
        let minLongitude = longitudes.min() ?? first.coordinate.longitude
        let maxLongitude = longitudes.max() ?? first.coordinate.longitude
        let latitudeDelta = max((maxLatitude - minLatitude) * 1.4, 0.01)
        let longitudeDelta = max((maxLongitude - minLongitude) * 1.4, 0.01)

        return .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLatitude + maxLatitude) / 2,
                longitude: (minLongitude + maxLongitude) / 2
            ),
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        ))
    }

    var body: some View {
        Map(position: $cameraPosition) {
            if locations.count > 1 {
                MapPolyline(coordinates: locations.map(\.coordinate))
                    .stroke(Color.accentColor, lineWidth: 5)
            }

            if let latest = locations.last {
                Annotation("", coordinate: latest.coordinate, anchor: .center) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.18))
                            .frame(width: 34, height: 34)
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 16, height: 16)
                            .overlay {
                                Circle()
                                    .stroke(.white, lineWidth: 3)
                            }
                    }
                    .accessibilityLabel(Text("map.currentLocation"))
                }
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onAppear {
            cameraPosition = targetCameraPosition
        }
        .onChange(of: locations.count) { _, _ in
            withAnimation(.easeInOut(duration: 0.35)) {
                cameraPosition = targetCameraPosition
            }
        }
    }
}
