import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var transactionKind: TransactionKind?
    @State private var selectedChart = DashboardChart.cashFlow
    @State private var summaryKind: TransactionKind?

    private var income: Double { store.currentMonthTotal(.income) }
    private var expenses: Double { store.currentMonthTotal(.expense) }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 18 { return "Good afternoon" }
        return "Good evening"
    }

    private var displayName: String {
        let trimmed = store.profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Nomad" : trimmed
    }

    enum DashboardChart: String, CaseIterable, Identifiable {
        case cashFlow = "Cash flow"
        case categories = "Categories"
        case accounts = "Accounts"
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AnimatedCard(delay: 0.0) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.teal, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 54, height: 54)

                            Text(String(displayName.prefix(1)).uppercased())
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(greeting.uppercased())
                                .font(.caption.bold())
                                .tracking(1.2)
                                .foregroundStyle(.teal)

                            Text(displayName)
                                .font(.title.bold())

                            Text("Here is your financial overview")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "person.crop.circle")
                                .font(.title2)
                                .foregroundStyle(.primary)
                                .frame(width: 44, height: 44)
                                .background(.secondary.opacity(0.12), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [
                                Color.teal.opacity(0.14),
                                Color.blue.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(.teal.opacity(0.18))
                    )
                }

                AnimatedCard(delay: 0.02) {
                    HStack(spacing: 12) {
                        Button { summaryKind = .income } label: { MetricCard(title: "Income", value: store.money(income), color: .green) }.buttonStyle(.plain)
                        Button { summaryKind = .expense } label: { MetricCard(title: "Expenses", value: store.money(expenses), color: .red) }.buttonStyle(.plain)
                    }
                }

                AnimatedCard(delay: 0.07) {
                    MetricCard(
                        title: "Remaining this month",
                        value: store.money(income - expenses),
                        color: income - expenses >= 0 ? .blue : .red
                    )
                }

                AnimatedCard(delay: 0.10) {
                    SectionCard(title: "Major expense budgets") {
                        if store.budgets.isEmpty {
                            NavigationLink("Create your first budget") { BudgetsView() }
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(Array(store.budgets.sorted { store.spent(for: $0) > store.spent(for: $1) }.prefix(4))) { budget in
                                    NavigationLink { BudgetsView() } label: {
                                        let spent = store.spent(for: budget)
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(budget.category).font(.caption.bold()).lineLimit(1)
                                            Text(store.money(max(0, budget.limit - spent), currency: budget.currency)).font(.headline)
                                            Text("left of \(store.money(budget.limit, currency: budget.currency))").font(.caption2).foregroundStyle(.secondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                                        .background(.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                                    }.buttonStyle(.plain)
                                }
                            }
                            NavigationLink("View and modify all budgets") { BudgetsView() }
                                .font(.subheadline.bold()).frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }

                AnimatedCard(delay: 0.12) {
                    HStack(spacing: 12) {
                        Button {
                            AppHaptics.impact()
                            transactionKind = .income
                        } label: {
                            Label("Money In", systemImage: "arrow.down")
                        }
                        .buttonStyle(ScalePressButtonStyle(tint: .green))

                        Button {
                            AppHaptics.impact()
                            transactionKind = .expense
                        } label: {
                            Label("Money Out", systemImage: "arrow.up")
                        }
                        .buttonStyle(ScalePressButtonStyle(tint: .red))
                    }
                }

                AnimatedCard(delay: 0.17) {
                    SectionCard(title: "Financial charts") {
                        Picker("Chart", selection: $selectedChart) {
                            ForEach(DashboardChart.allCases) { chart in
                                Text(chart.rawValue).tag(chart)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedChart) { _ in
                            AppHaptics.selection()
                        }

                        Group {
                            switch selectedChart {
                            case .cashFlow:
                                CashFlowChart()
                            case .categories:
                                CategoryChart()
                            case .accounts:
                                AccountBalanceChart()
                            }
                        }
                        .frame(height: 230)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        .animation(.easeInOut(duration: 0.24), value: selectedChart)
                    }
                }

                AnimatedCard(delay: 0.22) {
                    SectionCard(title: "Recent transactions") {
                        if store.transactions.isEmpty {
                            EmptyMessage(
                                icon: "arrow.left.arrow.right.circle",
                                title: "No transactions yet",
                                message: "Use Money In or Money Out to add your first transaction."
                            )
                        } else {
                            ForEach(store.transactions.prefix(5)) { item in
                                TransactionRow(item: item)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                if item.id != store.transactions.prefix(5).last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                AnimatedCard(delay: 0.27) {
                    SectionCard(title: "Accounts") {
                        if store.accounts.isEmpty {
                            EmptyMessage(
                                icon: "creditcard.circle",
                                title: "No accounts yet",
                                message: "Add a bank, cash, savings or wallet account."
                            )
                        } else {
                            ForEach(store.accounts.prefix(4)) { account in
                                HStack {
                                    Image(systemName: account.type == .cash ? "banknote" : "creditcard")
                                        .foregroundStyle(.teal)
                                    VStack(alignment: .leading) {
                                        Text(account.name).font(.headline)
                                        Text("\(account.type.rawValue) · \(account.currency)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(store.money(store.balance(for: account), currency: account.currency))
                                        .fontWeight(.semibold)
                                }
                                .padding(.vertical, 5)
                            }
                        }
                    }
                }

                AnimatedCard(delay: 0.32) {
                    SectionCard(title: "Save your first 1 million") {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("1,000,000 \(store.millionCurrency)")
                                    .font(.title2.bold())
                                Text("Guided savings plan")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("COMING SOON")
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.purple.opacity(0.15), in: Capsule())
                                .foregroundStyle(.purple)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Overview")
        .animation(.spring(response: 0.42, dampingFraction: 0.88), value: store.transactions)
        .sheet(item: $transactionKind) { kind in
            TransactionFormView(kind: kind)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $summaryKind) { kind in
            TransactionSummaryView(kind: kind)
        }
    }
}

struct TransactionSummaryView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    let kind: TransactionKind
    @State private var period = 0

    private var filtered: [FinanceTransaction] {
        store.transactions.filter { item in
            guard item.kind == kind else { return false }
            return period == 1 || Calendar.current.isDate(item.date, equalTo: Date(), toGranularity: .month)
        }
    }

    var body: some View {
        NavigationView {
            List {
                Picker("Period", selection: $period) {
                    Text("This month").tag(0)
                    Text("All time").tag(1)
                }.pickerStyle(.segmented)
                Section {
                    let total = filtered.reduce(0.0) { result, item in
                        result + store.convertedToMain(item.amount, from: store.account(for: item.accountID)?.currency ?? store.mainCurrency)
                    }
                    LabeledContent(kind == .income ? "Total income" : "Total expenses", value: store.money(total))
                        .font(.headline)
                }
                Section(kind == .income ? "Income records" : "Expense records") {
                    if filtered.isEmpty { Text("No records for this period.").foregroundStyle(.secondary) }
                    ForEach(filtered) { TransactionRow(item: $0) }
                }
            }
            .navigationTitle(kind.rawValue)
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}

private struct MonthlyCashPoint: Identifiable {
    let id = UUID()
    let month: String
    let kind: String
    let amount: Double
}

private struct CategoryPoint: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
}

private struct AccountPoint: Identifiable {
    let id = UUID()
    let name: String
    let balance: Double
}

private struct CashFlowChart: View {
    @EnvironmentObject private var store: FinanceStore

    private var points: [MonthlyCashPoint] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        return (0..<6).reversed().flatMap { offset -> [MonthlyCashPoint] in
            guard let monthDate = calendar.date(byAdding: .month, value: -offset, to: Date()),
                  let interval = calendar.dateInterval(of: .month, for: monthDate) else {
                return []
            }

            let income = store.transactions
                .filter { $0.kind == .income && interval.contains($0.date) }
                .reduce(0.0) { result, item in
                    result + store.convertedToMain(
                        item.amount,
                        from: store.account(for: item.accountID)?.currency ?? store.mainCurrency
                    )
                }

            let expense = store.transactions
                .filter { $0.kind == .expense && interval.contains($0.date) }
                .reduce(0.0) { result, item in
                    result + store.convertedToMain(
                        item.amount,
                        from: store.account(for: item.accountID)?.currency ?? store.mainCurrency
                    )
                }

            return [
                MonthlyCashPoint(month: formatter.string(from: monthDate), kind: "Income", amount: income),
                MonthlyCashPoint(month: formatter.string(from: monthDate), kind: "Expense", amount: expense)
            ]
        }
    }

    var body: some View {
        if points.allSatisfy({ $0.amount == 0 }) {
            ChartEmptyState(message: "Add transactions to see monthly cash flow.")
        } else {
            Chart(points) { point in
                BarMark(
                    x: .value("Month", point.month),
                    y: .value("Amount", point.amount)
                )
                .foregroundStyle(by: .value("Type", point.kind))
                .position(by: .value("Type", point.kind))
                .cornerRadius(4)
            }
            .chartForegroundStyleScale([
                "Income": Color.green,
                "Expense": Color.red
            ])
            .chartLegend(position: .bottom)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }
}

private struct CategoryChart: View {
    @EnvironmentObject private var store: FinanceStore

    private var points: [CategoryPoint] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: Date()) else { return [] }

        let grouped = Dictionary(grouping: store.transactions.filter {
            $0.kind == .expense && interval.contains($0.date)
        }, by: \.category)

        return grouped.map { category, items in
            CategoryPoint(
                category: category,
                amount: items.reduce(0.0) { result, item in
                    result + store.convertedToMain(
                        item.amount,
                        from: store.account(for: item.accountID)?.currency ?? store.mainCurrency
                    )
                }
            )
        }
        .sorted { $0.amount > $1.amount }
        .prefix(6)
        .map { $0 }
    }

    var body: some View {
        if points.isEmpty {
            ChartEmptyState(message: "Add expenses to see category spending.")
        } else {
            Chart(points) { point in
                BarMark(
                    x: .value("Amount", point.amount),
                    y: .value("Category", point.category)
                )
                .foregroundStyle(.teal.gradient)
                .cornerRadius(5)
            }
            .chartXAxis {
                AxisMarks(position: .bottom)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }
}

private struct AccountBalanceChart: View {
    @EnvironmentObject private var store: FinanceStore

    private var points: [AccountPoint] {
        store.accounts
            .map { account in
                AccountPoint(
                    name: account.name,
                    balance: store.convertedToMain(store.balance(for: account), from: account.currency)
                )
            }
            .sorted { $0.balance > $1.balance }
            .prefix(6)
            .map { $0 }
    }

    var body: some View {
        if points.isEmpty {
            ChartEmptyState(message: "Add accounts to compare balances.")
        } else {
            Chart(points) { point in
                BarMark(
                    x: .value("Account", point.name),
                    y: .value("Balance", point.balance)
                )
                .foregroundStyle(.teal.gradient)
                .cornerRadius(6)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }
}

private struct ChartEmptyState: View {
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundStyle(.teal)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
                .animation(.easeInOut(duration: 0.2), value: value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(.secondary.opacity(0.15)))
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.title3.bold())
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.secondary.opacity(0.15)))
    }
}

struct EmptyMessage: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.largeTitle).foregroundStyle(.teal)
            Text(title).font(.headline)
            Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
    }
}
