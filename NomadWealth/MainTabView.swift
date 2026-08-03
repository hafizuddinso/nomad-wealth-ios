import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationView { DashboardView() }
                .tabItem { Label("Dashboard", systemImage: "house") }

            NavigationView { AccountsView() }
                .tabItem { Label("Accounts", systemImage: "creditcard") }

            NavigationView { TransactionsView() }
                .tabItem { Label("Transactions", systemImage: "arrow.left.arrow.right") }

            NavigationView { LoansView() }
                .tabItem { Label("Loans", systemImage: "building.columns") }

            NavigationView { MoreView() }
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
        }
    }
}
