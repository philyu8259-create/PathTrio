import CoreLocation
import MapKit
import SwiftUI

struct RouteMapView: View {
    let locations: [CLLocation]
    var followsLatestLocation = false
    var style: PathTrioMapStyle = .standard

    @State private var cameraPosition: MapCameraPosition = .automatic

    private var displayCoordinates: [CLLocationCoordinate2D] {
        locations.map { MapDisplayCoordinateTransformer.displayCoordinate(for: $0.coordinate) }
    }

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

        let firstDisplayCoordinate = MapDisplayCoordinateTransformer.displayCoordinate(for: first.coordinate)

        guard locations.count > 1 else {
            return .region(MKCoordinateRegion(
                center: firstDisplayCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }

        let coordinates = displayCoordinates
        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        let minLatitude = latitudes.min() ?? firstDisplayCoordinate.latitude
        let maxLatitude = latitudes.max() ?? firstDisplayCoordinate.latitude
        let minLongitude = longitudes.min() ?? firstDisplayCoordinate.longitude
        let maxLongitude = longitudes.max() ?? firstDisplayCoordinate.longitude
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

            if displayCoordinates.count > 1 {
                MapPolyline(coordinates: displayCoordinates)
                    .stroke(Color.accentColor, lineWidth: 5)
            }

            if !followsLatestLocation, let latest = displayCoordinates.last {
                Annotation("", coordinate: latest, anchor: .center) {
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
