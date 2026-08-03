import SwiftUI
import Charts

struct MoreView: View {
    var body: some View {
        List {
            NavigationLink {
                AnalyticsView()
            } label: {
                Label("Analytics", systemImage: "chart.xyaxis.line")
            }

            NavigationLink {
                BudgetsView()
            } label: {
                Label("Budgets", systemImage: "chart.pie")
            }

            NavigationLink {
                CalculatorsView()
            } label: {
                Label("Calculators", systemImage: "sum")
            }

            NavigationLink {
                SettingsView()
            } label: {
                Label("Settings", systemImage: "gearshape")
            }

            NavigationLink {
                AboutView()
            } label: {
                Label("About Nomad Wealth", systemImage: "info.circle")
            }
        }
        .navigationTitle("More")
    }
}

struct BudgetsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showAdd = false

    var body: some View {
        List {
            if store.budgets.isEmpty {
                EmptyMessage(
                    icon: "chart.pie",
                    title: "No budgets yet",
                    message: "Add a category budget to plan monthly spending."
                )
                .listRowBackground(Color.clear)
            }

            ForEach(store.budgets) { budget in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(budget.category).font(.headline)
                        Spacer()
                        Text(store.money(budget.limit, currency: budget.currency))
                    }
                    Text("Monthly limit").font(.caption).foregroundStyle(.secondary)
                }
            }
            .onDelete { offsets in
                store.budgets.remove(atOffsets: offsets)
                store.save()
            }
        }
        .navigationTitle("Budgets")
        .toolbar {
            Button {
                showAdd = true
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
        .sheet(isPresented: $showAdd) {
            BudgetFormView()
        }
    }
}

struct BudgetFormView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var category = ""
    @State private var limit = 0.0
    @State private var currency = "EUR"

    var body: some View {
        NavigationView {
            Form {
                TextField("Category", text: $category)
                TextField("Monthly limit", value: $limit, format: .number)
                    .keyboardType(.decimalPad)
                Picker("Currency", selection: $currency) {
                    ForEach(["EUR","USD","GBP","RUB","BDT","ALL"], id: \.self) {
                        Text($0).tag($0)
                    }
                }
            }
            .navigationTitle("Add budget")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.budgets.append(Budget(category: category, limit: limit, currency: currency))
                        store.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CalculatorsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var principal = 10000.0
    @State private var rate = 8.0
    @State private var months = 36

    private var payment: Double {
        store.calculatedInstallment(principal: principal, annualRate: rate, months: months)
    }

    var body: some View {
        Form {
            Section("Loan installment calculator") {
                TextField("Principal", value: $principal, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Annual rate (%)", value: $rate, format: .number)
                    .keyboardType(.decimalPad)
                Stepper("Term: \(months) months", value: $months, in: 1...600)
            }

            Section("Estimate") {
                LabeledContent("Monthly payment", value: store.money(payment))
                LabeledContent("Total payment", value: store.money(payment * Double(months)))
                LabeledContent("Estimated interest", value: store.money(max(0, payment * Double(months) - principal)))
            }
        }
        .navigationTitle("Calculators")
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: FinanceStore

    private var initials: String {
        let name = store.profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { return "N" }
        let parts = name.split(separator: " ")
        return parts.prefix(2).compactMap { $0.first }.map(String.init).joined().uppercased()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                profileHeader
                profileStats
                personalDetails
                appearanceSettings
                currencySettings
                securityActions
            }
            .padding()
        }
        .navigationTitle("Profile")
        .background(Color(.systemGroupedBackground))
        .onChange(of: store.appearance) { _ in store.save() }
        .onChange(of: store.appFont) { _ in store.save() }
        .onChange(of: store.mainCurrency) { _ in store.save() }
        .onChange(of: store.millionCurrency) { _ in store.save() }
    }

    private var profileHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.teal, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 92, height: 92)

                Text(initials)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
            }
            .shadow(color: .teal.opacity(0.22), radius: 16, y: 8)

            Text(store.profile.name.isEmpty ? "Nomad Wealth User" : store.profile.name)
                .font(.title2.bold())

            Text(store.profile.email)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("PERSONAL FINANCE PROFILE")
                .font(.caption2.bold())
                .tracking(1.1)
                .foregroundStyle(.teal)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.teal.opacity(0.12), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .background(
            LinearGradient(
                colors: [
                    Color.teal.opacity(0.15),
                    Color.blue.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.teal.opacity(0.18))
        )
    }

    private var profileStats: some View {
        HStack(spacing: 10) {
            ProfileStat(value: "\(store.accounts.count)", title: "Accounts", icon: "creditcard")
            ProfileStat(value: "\(store.transactions.count)", title: "Entries", icon: "arrow.left.arrow.right")
            ProfileStat(value: "\(store.loans.count)", title: "Loans", icon: "building.columns")
        }
    }

    private var personalDetails: some View {
        ProfileSection(title: "Personal details", icon: "person.text.rectangle") {
            VStack(spacing: 12) {
                ProfileTextField(title: "Name", text: $store.profile.name)
                ProfileTextField(title: "Email", text: $store.profile.email, email: true)

                Button {
                    store.save()
                    AppHaptics.success()
                } label: {
                    Label("Save profile", systemImage: "checkmark.circle")
                }
                .buttonStyle(ScalePressButtonStyle(tint: .teal))
            }
        }
    }

    private var appearanceSettings: some View {
        ProfileSection(title: "Appearance", icon: "paintbrush") {
            VStack(spacing: 14) {
                Picker("Theme", selection: $store.appearance) {
                    ForEach(Appearance.allCases) {
                        Text($0.title).tag($0)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Font style")
                        .font(.subheadline.bold())

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 10
                    ) {
                        ForEach(AppFont.allCases) { font in
                            Button {
                                store.appFont = font
                                store.save()
                                AppHaptics.selection()
                            } label: {
                                VStack(spacing: 5) {
                                    Text("Aa")
                                        .font(.system(.title2, design: font.design))
                                        .fontWeight(.bold)
                                    Text(font.title)
                                        .font(.caption.bold())
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .foregroundStyle(store.appFont == font ? .white : .primary)
                                .background(
                                    store.appFont == font
                                    ? Color.teal
                                    : Color.secondary.opacity(0.10),
                                    in: RoundedRectangle(cornerRadius: 14)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var currencySettings: some View {
        ProfileSection(title: "Currency preferences", icon: "coloncurrencysign.circle") {
            VStack(spacing: 12) {
                Picker("Main currency", selection: $store.mainCurrency) {
                    ForEach(["EUR","USD","GBP","RUB","BDT","ALL","CAD","AUD"], id: \.self) {
                        Text($0).tag($0)
                    }
                }
                .pickerStyle(.menu)

                Picker("First 1 million goal", selection: $store.millionCurrency) {
                    ForEach(["EUR","USD","GBP","RUB","BDT","ALL","CAD","AUD"], id: \.self) {
                        Text("1,000,000 \($0)").tag($0)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var securityActions: some View {
        ProfileSection(title: "Account", icon: "lock.shield") {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Supabase authentication")
                            .font(.subheadline.bold())
                        Text("Your login is connected to the same account as the website.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Button(role: .destructive) {
                    store.logOut()
                    AppHaptics.impact()
                } label: {
                    Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .background(.red.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}

private struct ProfileSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.secondary.opacity(0.14))
        )
    }
}

private struct ProfileStat: View {
    let value: String
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .foregroundStyle(.teal)
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.background, in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(.secondary.opacity(0.13)))
    }
}

private struct ProfileTextField: View {
    let title: String
    @Binding var text: String
    var email = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            TextField(title, text: $text)
                .textInputAutocapitalization(email ? .never : .words)
                .keyboardType(email ? .emailAddress : .default)
                .padding(12)
                .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 13))
        }
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "location.north.circle.fill")
                    .font(.system(size: 68))
                    .foregroundStyle(.teal)

                Text("Nomad Wealth")
                    .font(.largeTitle.bold())

                Text("A native personal finance app for people managing money across countries and currencies.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Text("Developed by Hafizuddin")
                    .font(.footnote)
            }
            .padding(30)
        }
        .navigationTitle("About")
    }
}


struct AnalyticsView: View {
    @EnvironmentObject private var store: FinanceStore

    private struct DailyPoint: Identifiable {
        let id = UUID()
        let date: Date
        let income: Double
        let expense: Double
    }

    private var points: [DailyPoint] {
        let calendar = Calendar.current
        return (0..<30).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else {
                return nil
            }

            let income = store.transactions
                .filter { $0.kind == .income && calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(0.0) { result, item in
                    result + store.convertedToMain(
                        item.amount,
                        from: store.account(for: item.accountID)?.currency ?? store.mainCurrency
                    )
                }

            let expense = store.transactions
                .filter { $0.kind == .expense && calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(0.0) { result, item in
                    result + store.convertedToMain(
                        item.amount,
                        from: store.account(for: item.accountID)?.currency ?? store.mainCurrency
                    )
                }

            return DailyPoint(date: date, income: income, expense: expense)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SectionCard(title: "30-day cash flow") {
                    Chart(points) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Income", point.income)
                        )
                        .foregroundStyle(.green)
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Expense", point.expense)
                        )
                        .foregroundStyle(.red)
                        .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 250)
                    .chartLegend(position: .bottom)
                }

                SectionCard(title: "Net position") {
                    let accountTotal = store.accounts.reduce(0.0) { result, account in
                        result + store.convertedToMain(
                            store.balance(for: account),
                            from: account.currency
                        )
                    }

                    let debtTotal = store.loans.reduce(0.0) { result, loan in
                        result + store.convertedToMain(
                            loan.remainingPrincipal,
                            from: loan.currency
                        )
                    }

                    Chart {
                        BarMark(
                            x: .value("Type", "Accounts"),
                            y: .value("Amount", accountTotal)
                        )
                        .foregroundStyle(.teal)

                        BarMark(
                            x: .value("Type", "Loans"),
                            y: .value("Amount", debtTotal)
                        )
                        .foregroundStyle(.orange)
                    }
                    .frame(height: 220)
                }
            }
            .padding()
        }
        .navigationTitle("Analytics")
    }
}
