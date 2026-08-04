import SwiftUI

struct MainTabView: View {
    @State private var selection = 0
    @State private var quickTransaction: TransactionKind?

    var body: some View {
        TabView(selection: $selection) {
            NavigationView { DashboardView() }.tabItem { Label("Dashboard", systemImage: "house") }.tag(0)
            NavigationView { AccountsView() }.tabItem { Label("Accounts", systemImage: "creditcard") }.tag(1)
            NavigationView { TransactionsView() }.tabItem { Label("Transactions", systemImage: "arrow.left.arrow.right") }.tag(2)
            NavigationView { LoansView() }.tabItem { Label("Loans", systemImage: "building.columns") }.tag(3)
            NavigationView { MoreView() }.tabItem { Label("More", systemImage: "ellipsis.circle") }.tag(4)
        }
        .onReceive(NotificationCenter.default.publisher(for: .nomadOpenDashboard)) { _ in selection = 0 }
        .onReceive(NotificationCenter.default.publisher(for: .nomadAddTransaction)) { _ in
            selection = 2
            quickTransaction = .expense
        }
        .sheet(item: $quickTransaction) { kind in
            TransactionFormView(kind: kind)
        }
    }
}
