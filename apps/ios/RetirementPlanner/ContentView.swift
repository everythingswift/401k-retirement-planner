import SwiftUI

struct ContentView: View {
    @State private var store = RetirementStore()
    @AppStorage("disclaimerSeen") private var disclaimerSeen = false

    var body: some View {
        NavigationStack {
            ConfigurationView(store: store)
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: Binding(
            get: { !disclaimerSeen },
            set: { _ in }
        )) {
            DisclaimerView {
                disclaimerSeen = true
            }
        }
    }
}

#Preview {
    ContentView()
}
