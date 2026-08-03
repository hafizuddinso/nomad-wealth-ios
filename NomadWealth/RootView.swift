import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        Group {
            if store.signedIn {
                MainTabView()
            } else {
                WelcomeView()
            }
        }
        .font(.system(.body, design: store.selectedFontDesign))
        .tint(.teal)
    }
}
