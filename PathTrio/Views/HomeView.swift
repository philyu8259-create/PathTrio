import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("PathTrio")
                .font(.largeTitle.bold())
            Text("Walk, Run & Ride Tracker")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
