import CoreLocation
import MapKit
import SwiftUI

struct RouteMapView: View {
    let locations: [CLLocation]
    var followsLatestLocation = false
    var style: PathTrioMapStyle = .standard

    @State private var cameraPosition: MapCameraPosition = .automatic

    private var defaultCameraPosition: MapCameraPosition {
        .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        ))
    }

    private var targetCameraPosition: MapCameraPosition {
        if followsLatestLocation {
            return .userLocation(followsHeading: false, fallback: defaultCameraPosition)
        }

        guard let first = locations.first else {
            return defaultCameraPosition
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
            if followsLatestLocation {
                UserAnnotation()
            }

            if locations.count > 1 {
                MapPolyline(coordinates: locations.map(\.coordinate))
                    .stroke(Color.accentColor, lineWidth: 5)
            }

            if !followsLatestLocation, let latest = locations.last {
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
        .pathTrioMapStyle(style)
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

private extension View {
    @ViewBuilder
    func pathTrioMapStyle(_ style: PathTrioMapStyle) -> some View {
        switch style {
        case .standard:
            mapStyle(.standard)
        case .hybrid:
            mapStyle(.hybrid(elevation: .realistic))
        case .imagery:
            mapStyle(.imagery(elevation: .realistic))
        }
    }
}
