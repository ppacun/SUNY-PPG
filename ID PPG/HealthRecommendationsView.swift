import SwiftUI

struct HealthRecommendationsView: View {

    //@Binding var path: NavigationPath

    var body: some View {

        VStack {
            NavigationLink {
                ResultsView(
                     averageBPM: 60,
                     confidancePCT: 99.9
                )
            } label: {
                Text("Health Recommendations\nto be implemented")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
            }
        }
    }
}
