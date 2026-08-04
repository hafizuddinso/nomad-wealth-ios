import SwiftUI

struct SharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

struct RootView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var sharePayload: SharePayload?

    private var shareURL: URL {
        URL(string: "https://nomad-wealth.vercel.app")!
    }

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
        .onReceive(NotificationCenter.default.publisher(for: .nomadShareApp)) { _ in
            sharePayload = SharePayload(items: [
                "Track accounts, budgets, investments, loans and travel money with Nomad Wealth.",
                shareURL
            ])
        }
        .sheet(item: $sharePayload) { payload in
            ActivityView(items: payload.items)
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
