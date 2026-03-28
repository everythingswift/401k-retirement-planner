import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Retirement Planner")
                    .font(.title2.weight(.semibold))
                Text("SwiftUI shell — connect inputs and charts to ported core logic next.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("401(k)")
        }
    }
}

#Preview {
    ContentView()
}
