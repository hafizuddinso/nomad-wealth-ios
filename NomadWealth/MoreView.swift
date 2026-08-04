import SwiftUI
import Charts
import PhotosUI
import UIKit

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
                InvestmentsView()
            } label: {
                Label("Investments", systemImage: "chart.line.uptrend.xyaxis")
            }

            NavigationLink {
                TravelModeView()
            } label: {
                Label("Travel mode", systemImage: "airplane")
            }

            NavigationLink {
                CurrencyConverterView()
            } label: {
                Label("Currency converter", systemImage: "arrow.left.arrow.right.circle")
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
    @State private var selectedBudget: Budget?

    var body: some View {
        List {
            if store.budgets.isEmpty {
                EmptyMessage(icon: "chart.pie", title: "No budgets yet", message: "Create a connected weekly, monthly or yearly budget.")
                    .listRowBackground(Color.clear)
            }
            ForEach(store.budgets) { budget in
                Button { selectedBudget = budget } label: { BudgetProgressRow(budget: budget) }
                    .buttonStyle(.plain)
            }
            .onDelete { store.budgets.remove(atOffsets: $0); store.save() }

            Section {
                Button { showAdd = true } label: {
                    Label("Add budget", systemImage: "plus.circle.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Budgets")
        .sheet(isPresented: $showAdd) { BudgetFormView() }
        .sheet(item: $selectedBudget) { BudgetFormView(existing: $0) }
    }
}

struct BudgetProgressRow: View {
    @EnvironmentObject private var store: FinanceStore
    let budget: Budget
    var body: some View {
        let spent = store.spent(for: budget)
        let remaining = budget.limit - spent
        let progress = budget.limit > 0 ? min(spent / budget.limit, 1) : 0
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(budget.category).font(.headline)
                    if let account = budget.accountID.flatMap({ store.account(for: $0) }) {
                        Text("\(account.name) · \(account.currency)").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer(); Text(budget.period.rawValue).font(.caption).foregroundStyle(.secondary)
            }
            ProgressView(value: progress).tint(spent > budget.limit ? .red : .teal)
            HStack {
                Text("Spent \(store.money(spent, currency: budget.currency))")
                Spacer()
                Text(remaining >= 0 ? "Left \(store.money(remaining, currency: budget.currency))" : "Over \(store.money(abs(remaining), currency: budget.currency))")
                    .foregroundStyle(remaining >= 0 ? Color.secondary : Color.red)
            }.font(.caption)
        }.padding(.vertical, 5)
    }
}

struct BudgetFormView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    let existing: Budget?

    @State private var period: BudgetPeriod?
    @State private var accountID: UUID?
    @State private var category = ""
    @State private var limitText = ""
    @State private var startDate = Date()

    init(existing: Budget? = nil) { self.existing = existing }
    private var selectedAccount: Account? { accountID.flatMap { store.account(for: $0) } }

    var body: some View {
        NavigationView {
            Form {
                Picker("Select period", selection: $period) {
                    Text("Select period").tag(BudgetPeriod?.none)
                    ForEach(BudgetPeriod.allCases) { Text($0.rawValue).tag(Optional($0)) }
                }
                Picker("Select account", selection: $accountID) {
                    Text("Select account").tag(UUID?.none)
                    ForEach(store.accounts) { Text("\($0.name) · \($0.currency)").tag(Optional($0.id)) }
                }
                Picker("Select expense category", selection: $category) {
                    Text("Select category").tag("")
                    ForEach(FinanceStore.expenseCategories, id: \.self) { Text($0).tag($0) }
                }
                TextField("Enter spending limit", text: $limitText).keyboardType(.decimalPad)
                DatePicker("Budget period date", selection: $startDate, displayedComponents: .date)

                if existing != nil {
                    Button("Delete budget", role: .destructive) {
                        store.budgets.removeAll { $0.id == existing?.id }; store.save(); dismiss()
                    }
                }
            }
            .navigationTitle(existing == nil ? "Add budget" : "Edit budget")
            .onAppear {
                guard let existing else { return }
                period = existing.period; accountID = existing.accountID; category = existing.category
                limitText = String(existing.limit); startDate = existing.startDate
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let period, let account = selectedAccount, let limit = Double(limitText), limit > 0, !category.isEmpty else { return }
                        let item = Budget(id: existing?.id ?? UUID(), period: period, accountID: account.id, category: category, limit: limit, currency: account.currency, startDate: startDate)
                        if let i = store.budgets.firstIndex(where: { $0.id == item.id }) { store.budgets[i] = item } else { store.budgets.append(item) }
                        store.save(); dismiss()
                    }
                    .disabled(period == nil || selectedAccount == nil || category.isEmpty || (Double(limitText) ?? 0) <= 0)
                }
            }
        }
    }
}

struct InvestmentsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showAdd = false
    @State private var selectedInvestment: Investment?

    var body: some View {
        List {
            if store.investments.isEmpty {
                EmptyMessage(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "No investments yet",
                    message: "Add an investment to track previous cost, current value and performance."
                )
                .listRowBackground(Color.clear)
            }

            if !store.investments.isEmpty {
                Section {
                    Chart(store.investments) { item in
                        BarMark(
                            x: .value("Investment", item.name),
                            y: .value("Value", item.currentValue)
                        )
                        .foregroundStyle(.teal.gradient)
                    }
                    .frame(height: 220)
                }
            }

            ForEach(store.investments) { item in
                Button {
                    selectedInvestment = item
                } label: {
                    InvestmentRow(item: item)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Investments")
        .toolbar {
            Button {
                showAdd = true
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
        .sheet(isPresented: $showAdd) {
            InvestmentFormView()
        }
        .sheet(item: $selectedInvestment) { item in
            InvestmentFormView(existing: item)
        }
    }

    @ViewBuilder
    private func InvestmentRow(item: Investment) -> some View {
        let gain = item.currentValue - item.cost
        let percentage = item.cost > 0 ? gain / item.cost * 100 : 0

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(store.money(item.currentValue, currency: item.currency))
                    .bold()
                    .foregroundStyle(.primary)
            }

            Text(
                "Previous \(store.money(item.cost, currency: item.currency)) · " +
                "Now \(store.money(item.currentValue, currency: item.currency))"
            )

            Text(
                "\(gain >= 0 ? "Profit" : "Loss") " +
                "\(store.money(abs(gain), currency: item.currency)) · " +
                String(format: "%.1f%%", percentage)
            )
            .foregroundStyle(gain >= 0 ? Color.green : Color.red)
        }
        .font(.caption)
    }
}

struct InvestmentFormView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    let existing: Investment?

    @State private var name = ""
    @State private var type = ""
    @State private var accountID: UUID?
    @State private var costText = ""
    @State private var valueText = ""
    @State private var note = ""
    @State private var purchaseDate = Date()

    init(existing: Investment? = nil) {
        self.existing = existing
    }

    private var selectedAccount: Account? {
        guard let accountID else { return nil }
        return store.account(for: accountID)
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("Enter investment name", text: $name)
                TextField("Enter investment type", text: $type)

                Picker("Select account", selection: $accountID) {
                    Text("Select account").tag(UUID?.none)
                    ForEach(store.accounts) { account in
                        Text(account.name).tag(Optional(account.id))
                    }
                }

                if let selectedAccount {
                    LabeledContent("Currency", value: selectedAccount.currency)
                }

                TextField("Enter previous invested amount", text: $costText)
                    .keyboardType(.decimalPad)

                TextField("Enter current value", text: $valueText)
                    .keyboardType(.decimalPad)

                DatePicker(
                    "Purchase date",
                    selection: $purchaseDate,
                    displayedComponents: .date
                )

                TextField("Enter note", text: $note)
            }
            .navigationTitle(existing == nil ? "Add investment" : "Edit investment")
            .onAppear {
                guard let existing else { return }
                name = existing.name
                type = existing.type
                accountID = existing.accountID
                costText = String(existing.cost)
                valueText = String(existing.currentValue)
                purchaseDate = existing.purchaseDate
                note = existing.note
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard
                            let accountID,
                            let selectedAccount,
                            let cost = Double(costText),
                            let currentValue = Double(valueText),
                            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        else {
                            return
                        }

                        let investment = Investment(
                            id: existing?.id ?? UUID(),
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            type: type.trimmingCharacters(in: .whitespacesAndNewlines),
                            accountID: accountID,
                            currency: selectedAccount.currency,
                            cost: cost,
                            currentValue: currentValue,
                            purchaseDate: purchaseDate,
                            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
                        )

                        if let index = store.investments.firstIndex(where: { $0.id == investment.id }) {
                            store.investments[index] = investment
                        } else {
                            store.investments.append(investment)
                        }

                        store.save()
                        dismiss()
                    }
                    .disabled(
                        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        selectedAccount == nil ||
                        Double(costText) == nil ||
                        Double(valueText) == nil
                    )
                }
            }
        }
    }
}

struct TravelModeView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showAdd = false
    @State private var selectedPlan: TravelPlan?

    var body: some View {
        List {
            if store.travelPlans.isEmpty {
                EmptyMessage(icon: "airplane", title: "No travel plans", message: "Create a trip and get an automatic day-by-day budget.")
                    .listRowBackground(Color.clear)
                Section { centeredAddButton }
            } else {
                ForEach(store.travelPlans) { plan in
                    Button { selectedPlan = plan } label: { TravelPlanRow(plan: plan) }.buttonStyle(.plain)
                }
                Section { centeredAddButton }
            }
        }
        .navigationTitle("Travel mode")
        .toolbar { Button { showAdd = true } label: { Label("Add", systemImage: "plus") } }
        .sheet(isPresented: $showAdd) { TravelPlanFormView() }
        .sheet(item: $selectedPlan) { TravelPlanDetailView(planID: $0.id) }
    }

    private var centeredAddButton: some View {
        Button { showAdd = true } label: {
            Label("Add travel plan", systemImage: "plus.circle.fill")
                .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
        }.buttonStyle(.borderedProminent)
    }
}

struct TravelPlanRow: View {
    @EnvironmentObject private var store: FinanceStore
    let plan: TravelPlan
    var body: some View {
        let spent = store.travelSpent(plan)
        let left = plan.budget - spent
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text(plan.name).font(.headline); Spacer(); Text(plan.currency).font(.caption).foregroundStyle(.secondary) }
            Text("\(plan.origin ?? "Starting point") → \(plan.destination)").foregroundStyle(.secondary)
            Text("\(plan.dayCount) days · \(store.money(plan.automaticDailyBudget, currency: plan.currency)) available per day")
                .font(.caption).foregroundStyle(.secondary)
            ProgressView(value: plan.budget > 0 ? min(spent / plan.budget, 1) : 0).tint(left < 0 ? .red : .teal)
            HStack { Text("Spent \(store.money(spent, currency: plan.currency))"); Spacer(); Text(left >= 0 ? "Left \(store.money(left, currency: plan.currency))" : "Over \(store.money(abs(left), currency: plan.currency))") }.font(.caption)
        }.padding(.vertical, 6)
    }
}

struct TravelPlanDetailView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    let planID: UUID
    @State private var showEdit = false

    private var plan: TravelPlan? { store.travelPlans.first { $0.id == planID } }

    var body: some View {
        NavigationView {
            Group {
                if let plan {
                    List {
                        Section("Whole travel plan") {
                            LabeledContent("Route", value: "\(plan.origin ?? "Not set") → \(plan.destination)")
                            LabeledContent("Dates", value: "\(plan.startDate.formatted(date: .abbreviated, time: .omitted)) – \(plan.endDate.formatted(date: .abbreviated, time: .omitted))")
                            LabeledContent("Length", value: "\(plan.dayCount) days")
                            LabeledContent("Total budget", value: store.money(plan.budget, currency: plan.currency))
                            LabeledContent("Automatic daily budget", value: store.money(plan.automaticDailyBudget, currency: plan.currency))
                        }

                        Section("Planned cost per day") {
                            LabeledContent("Accommodation", value: store.money(plan.accommodationPerDay ?? 0, currency: plan.currency))
                            LabeledContent("Food", value: store.money(plan.foodPerDay ?? 0, currency: plan.currency))
                            LabeledContent("Local transport", value: store.money(plan.localTransportPerDay ?? 0, currency: plan.currency))
                            LabeledContent("Activities", value: store.money(plan.activitiesPerDay ?? 0, currency: plan.currency))
                            LabeledContent("Daily planned total", value: store.money(plan.plannedDailyCost, currency: plan.currency))
                            LabeledContent("One-time transport", value: store.money(plan.oneTimeTransport ?? 0, currency: plan.currency))
                            LabeledContent("Whole planned cost", value: store.money(plan.plannedTotal, currency: plan.currency))
                        }

                        Section("Day-by-day plan") {
                            ForEach(0..<plan.dayCount, id: \.self) { offset in
                                let date = Calendar.current.date(byAdding: .day, value: offset, to: plan.startDate) ?? plan.startDate
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Day \(offset + 1) · \(date.formatted(date: .abbreviated, time: .omitted))").font(.headline)
                                    Text("Daily budget: \(store.money(plan.automaticDailyBudget, currency: plan.currency))")
                                    Text("Planned: \(store.money(plan.plannedDailyCost, currency: plan.currency))")
                                        .foregroundStyle(plan.plannedDailyCost <= plan.automaticDailyBudget ? Color.green : Color.red)
                                }
                            }
                        }

                        Section("Actual spending") {
                            let spent = store.travelSpent(plan)
                            LabeledContent("Spent", value: store.money(spent, currency: plan.currency))
                            LabeledContent("Remaining", value: store.money(plan.budget - spent, currency: plan.currency))
                            ProgressView(value: plan.budget > 0 ? min(spent / plan.budget, 1) : 0)
                        }

                        if let notes = plan.notes, !notes.isEmpty { Section("Notes") { Text(notes) } }
                    }
                } else { Text("Travel plan not found.") }
            }
            .navigationTitle(plan?.name ?? "Travel plan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Modify") { showEdit = true } }
            }
            .sheet(isPresented: $showEdit) { if let plan { TravelPlanFormView(existing: plan) } }
        }
    }
}

struct TravelPlanFormView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    let existing: TravelPlan?

    @State private var name = ""
    @State private var origin = ""
    @State private var destination = ""
    @State private var accountID: UUID?
    @State private var budgetText = ""
    @State private var accommodationText = ""
    @State private var foodText = ""
    @State private var localTransportText = ""
    @State private var activitiesText = ""
    @State private var oneTimeTransportText = ""
    @State private var notes = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    init(existing: TravelPlan? = nil) { self.existing = existing }
    private var selectedAccount: Account? { accountID.flatMap { store.account(for: $0) } }
    private var days: Int { max(1, (Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0) + 1) }
    private var budget: Double { Double(budgetText.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    var body: some View {
        NavigationView {
            Form {
                Section("Route and dates") {
                    TextField("Trip name", text: $name)
                    TextField("From", text: $origin)
                    TextField("To", text: $destination)
                    DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                Section("Budget") {
                    Picker("Funding account", selection: $accountID) {
                        Text("Select account").tag(UUID?.none)
                        ForEach(store.accounts) { Text("\($0.name) · \($0.currency)").tag(Optional($0.id)) }
                    }
                    TextField("Whole travel budget", text: $budgetText).keyboardType(.decimalPad)
                    if let account = selectedAccount, budget > 0 {
                        LabeledContent("Currency", value: account.currency)
                        LabeledContent("Number of days", value: "\(days)")
                        LabeledContent("Automatic budget per day", value: store.money(budget / Double(days), currency: account.currency))
                    }
                }
                Section("Planned daily spending") {
                    TextField("Accommodation per day", text: $accommodationText).keyboardType(.decimalPad)
                    TextField("Food per day", text: $foodText).keyboardType(.decimalPad)
                    TextField("Local transport per day", text: $localTransportText).keyboardType(.decimalPad)
                    TextField("Activities per day", text: $activitiesText).keyboardType(.decimalPad)
                    TextField("Flights / train / one-time transport", text: $oneTimeTransportText).keyboardType(.decimalPad)
                }
                Section("Notes") { TextField("Places, bookings or reminders", text: $notes, axis: .vertical) }
                if existing != nil {
                    Section { Button("Delete travel plan", role: .destructive) { store.travelPlans.removeAll { $0.id == existing?.id }; store.save(); dismiss() } }
                }
            }
            .navigationTitle(existing == nil ? "Add travel plan" : "Edit travel plan")
            .onAppear {
                guard let item = existing else { return }
                name = item.name; origin = item.origin ?? ""; destination = item.destination; accountID = item.accountID
                budgetText = String(item.budget); startDate = item.startDate; endDate = item.endDate
                accommodationText = item.accommodationPerDay.map { String($0) } ?? ""; foodText = item.foodPerDay.map { String($0) } ?? ""
                localTransportText = item.localTransportPerDay.map { String($0) } ?? ""; activitiesText = item.activitiesPerDay.map { String($0) } ?? ""
                oneTimeTransportText = item.oneTimeTransport.map { String($0) } ?? ""; notes = item.notes ?? ""
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let account = selectedAccount, budget > 0, !name.trimmingCharacters(in: .whitespaces).isEmpty, !destination.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let item = TravelPlan(id: existing?.id ?? UUID(), name: name.trimmingCharacters(in: .whitespaces), origin: origin.trimmingCharacters(in: .whitespaces), destination: destination.trimmingCharacters(in: .whitespaces), accountID: account.id, currency: account.currency, budget: budget, startDate: startDate, endDate: endDate, accommodationPerDay: Double(accommodationText), foodPerDay: Double(foodText), localTransportPerDay: Double(localTransportText), activitiesPerDay: Double(activitiesText), oneTimeTransport: Double(oneTimeTransportText), notes: notes)
                        if let index = store.travelPlans.firstIndex(where: { $0.id == item.id }) { store.travelPlans[index] = item } else { store.travelPlans.append(item) }
                        store.save(); dismiss()
                    }
                    .disabled(selectedAccount == nil || budget <= 0 || name.trimmingCharacters(in: .whitespaces).isEmpty || destination.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct CurrencyConverterView: View {
    @EnvironmentObject private var store: FinanceStore

    @State private var amountText = ""
    @State private var fromCurrency = ""
    @State private var toCurrency = ""

    private let currencies = ["EUR", "USD", "GBP", "RUB", "BDT", "ALL", "CAD", "AUD"]

    var body: some View {
        Form {
            TextField("Enter amount", text: $amountText)
                .keyboardType(.decimalPad)

            Picker("From currency", selection: $fromCurrency) {
                Text("Select currency").tag("")
                ForEach(currencies, id: \.self) { currency in
                    Text(currency).tag(currency)
                }
            }

            Picker("To currency", selection: $toCurrency) {
                Text("Select currency").tag("")
                ForEach(currencies, id: \.self) { currency in
                    Text(currency).tag(currency)
                }
            }

            if
                let amount = Double(amountText),
                !fromCurrency.isEmpty,
                !toCurrency.isEmpty
            {
                Section("Converted amount") {
                    Text(
                        store.money(
                            store.convert(amount, from: fromCurrency, to: toCurrency),
                            currency: toCurrency
                        )
                    )
                    .font(.title2.bold())
                }
            }

            Section {
                Text("Reference rates are stored in the app and may differ from live market rates.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Currency converter")
    }
}

struct CalculatorsView: View {
    @EnvironmentObject private var store: FinanceStore

    @State private var principalText = ""
    @State private var rateText = ""
    @State private var months = 12

    private var payment: Double {
        store.calculatedInstallment(
            principal: Double(principalText) ?? 0,
            annualRate: Double(rateText) ?? 0,
            months: months
        )
    }

    var body: some View {
        Form {
            Section("Loan installment calculator") {
                TextField("Enter principal", text: $principalText)
                    .keyboardType(.decimalPad)

                TextField("Enter annual rate (%)", text: $rateText)
                    .keyboardType(.decimalPad)

                Stepper("Term: \(months) months", value: $months, in: 1...600)
            }

            Section("Estimate") {
                LabeledContent("Monthly payment", value: store.money(payment))
                LabeledContent("Total payment", value: store.money(payment * Double(months)))
            }
        }
        .navigationTitle("Calculators")
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var photoItem: PhotosPickerItem?
    @State private var showShareSheet = false
    @State private var showResetConfirmation = false
    @State private var showStatement = false
    @State private var newPassword = ""
    @State private var passwordMessage = ""
    @State private var isUpdatingPassword = false

    private let currencies = ["EUR", "USD", "GBP", "RUB", "BDT", "ALL", "CAD", "AUD"]
    private var initials: String { let value = store.profile.name.split(separator: " ").prefix(2).compactMap(\.first).map { String($0) }.joined().uppercased(); return value.isEmpty ? "N" : value }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                profileHeader

                settingsBox(title: "Personal information", icon: "person.text.rectangle") {
                    TextField("Full name", text: $store.profile.name).textFieldStyle(.roundedBorder)
                    TextField("Email address", text: $store.profile.email).textFieldStyle(.roundedBorder).textInputAutocapitalization(.never).keyboardType(.emailAddress)
                    Button("Save personal information") { store.save(); AppHaptics.success() }.buttonStyle(.borderedProminent).frame(maxWidth: .infinity)
                }

                settingsBox(title: "Change password", icon: "lock.rotation") {
                    SecureField("New password (minimum 6 characters)", text: $newPassword).textFieldStyle(.roundedBorder)
                    if !passwordMessage.isEmpty { Text(passwordMessage).font(.footnote).foregroundStyle(passwordMessage.contains("updated") ? Color.green : Color.red) }
                    Button(isUpdatingPassword ? "Updating…" : "Change password") {
                        Task {
                            guard newPassword.count >= 6 else { passwordMessage = "Password must contain at least 6 characters."; return }
                            isUpdatingPassword = true
                            do { try await SupabaseAuthService.shared.updatePassword(newPassword); passwordMessage = "Password updated successfully."; newPassword = "" }
                            catch { passwordMessage = error.localizedDescription }
                            isUpdatingPassword = false
                        }
                    }.buttonStyle(.borderedProminent).disabled(isUpdatingPassword || newPassword.count < 6)
                }

                settingsBox(title: "Appearance", icon: "paintbrush") {
                    Picker("Theme", selection: $store.appearance) { ForEach(Appearance.allCases) { Text($0.title).tag($0) } }.pickerStyle(.menu)
                    Picker("Font", selection: $store.appFont) { ForEach(AppFont.allCases) { Text($0.title).tag($0) } }.pickerStyle(.menu)
                    Button("Save appearance") { store.save(); AppHaptics.success() }.buttonStyle(.borderedProminent)
                }

                settingsBox(title: "Currency preferences", icon: "dollarsign.circle") {
                    Picker("Main reporting currency", selection: $store.mainCurrency) { ForEach(currencies, id: \.self) { Text($0).tag($0) } }.pickerStyle(.menu)
                    Text("This controls dashboard and report display. Account currencies remain unchanged.").font(.footnote).foregroundStyle(.secondary)
                    Button("Save currency") { store.save(); AppHaptics.success() }.buttonStyle(.borderedProminent)
                }

                settingsBox(title: "Statements and reports", icon: "doc.richtext") {
                    Text("Generate a PDF statement for a week, month, three months or a custom date range.").font(.footnote).foregroundStyle(.secondary)
                    Button { showStatement = true } label: { Label("Generate monthly statement", systemImage: "doc.badge.arrow.up") }.buttonStyle(.borderedProminent)
                }

                settingsBox(title: "Data and reset", icon: "arrow.counterclockwise") {
                    Text("Reset removes accounts, transactions, budgets, investments, travel plans and loans from this device.").font(.footnote).foregroundStyle(.secondary)
                    Button("Reset all financial data", role: .destructive) { showResetConfirmation = true }.buttonStyle(.bordered)
                }

                Button { showShareSheet = true } label: { Label("Share Nomad Wealth", systemImage: "square.and.arrow.up") }.buttonStyle(.borderedProminent)
                Button("Log out", role: .destructive) { store.logOut() }
            }.padding()
        }
        .navigationTitle("Profile & Settings")
        .onChange(of: photoItem) { item in Task { guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }; store.profile.photoData = data; store.save() } }
        .sheet(isPresented: $showShareSheet) { ActivityView(items: ["Track your money with Nomad Wealth", URL(string: "https://nomad-wealth.vercel.app")!]) }
        .sheet(isPresented: $showStatement) { StatementGeneratorView() }
        .confirmationDialog("Reset all financial data?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("Reset everything", role: .destructive) { store.resetFinancialData() }
            Button("Cancel", role: .cancel) { }
        } message: { Text("This cannot be undone on this device.") }
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            if let data = store.profile.photoData, let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFill().frame(width: 104, height: 104).clipShape(Circle()) }
            else { Circle().fill(LinearGradient(colors: [.teal, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 104, height: 104).overlay(Text(initials).font(.largeTitle.bold()).foregroundStyle(.white)) }
            PhotosPicker(selection: $photoItem, matching: .images) { Label("Change profile picture", systemImage: "photo") }
            if store.profile.photoData != nil { Button("Remove picture", role: .destructive) { store.profile.photoData = nil; store.save() } }
            Text(store.profile.name.isEmpty ? "Nomad Wealth User" : store.profile.name).font(.title2.bold())
            Text(store.profile.email).foregroundStyle(.secondary)
        }.padding().frame(maxWidth: .infinity).background(.teal.opacity(0.10), in: RoundedRectangle(cornerRadius: 24))
    }

    private func settingsBox<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon).font(.headline)
            content()
        }.padding().frame(maxWidth: .infinity, alignment: .leading).background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
    }
}

enum StatementRange: String, CaseIterable, Identifiable { case week = "Week", month = "Month", threeMonths = "3 Months", custom = "Specific dates"; var id: String { rawValue } }

struct StatementGeneratorView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var range: StatementRange = .month
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var pdfURL: URL?
    @State private var showShare = false

    private var resolvedDates: (Date, Date) {
        let calendar = Calendar.current
        let end = Date()
        switch range {
        case .week: return (calendar.date(byAdding: .day, value: -7, to: end) ?? end, end)
        case .month: return (calendar.date(byAdding: .month, value: -1, to: end) ?? end, end)
        case .threeMonths: return (calendar.date(byAdding: .month, value: -3, to: end) ?? end, end)
        case .custom: return (startDate, endDate)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Picker("Statement period", selection: $range) { ForEach(StatementRange.allCases) { Text($0.rawValue).tag($0) } }
                if range == .custom {
                    DatePicker("From", selection: $startDate, displayedComponents: .date)
                    DatePicker("To", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                Button { generatePDF() } label: { Label("Create PDF statement", systemImage: "doc.fill") }.buttonStyle(.borderedProminent)
                if pdfURL != nil { Button { showShare = true } label: { Label("Download or share PDF", systemImage: "square.and.arrow.up") } }
            }
            .navigationTitle("Statement generator")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showShare) { if let pdfURL { ActivityView(items: [pdfURL]) } }
        }
    }

    private func generatePDF() {
        let dates = resolvedDates
        let transactions = store.transactions.filter { $0.date >= dates.0 && $0.date <= dates.1 }.sorted { $0.date > $1.date }
        let income = transactions.filter { $0.kind == .income }.reduce(0) { $0 + store.convertedToMain($1.amount, from: store.account(for: $1.accountID)?.currency ?? store.mainCurrency) }
        let expenses = transactions.filter { $0.kind == .expense }.reduce(0) { $0 + store.convertedToMain($1.amount, from: store.account(for: $1.accountID)?.currency ?? store.mainCurrency) }
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Nomad-Wealth-Statement-\(Date().timeIntervalSince1970).pdf")
        try? renderer.writePDF(to: url) { context in
            var y: CGFloat = 36
            func draw(_ text: String, font: UIFont, color: UIColor = .label) {
                if y > 750 { context.beginPage(); y = 36 }
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                text.draw(in: CGRect(x: 36, y: y, width: 540, height: 40), withAttributes: attrs)
                y += font.pointSize + 10
            }
            context.beginPage()
            draw("Nomad Wealth Statement", font: .boldSystemFont(ofSize: 24))
            draw("\(dates.0.formatted(date: .abbreviated, time: .omitted)) – \(dates.1.formatted(date: .abbreviated, time: .omitted))", font: .systemFont(ofSize: 12), color: .secondaryLabel)
            draw("Income: \(store.money(income))", font: .boldSystemFont(ofSize: 16), color: .systemGreen)
            draw("Expenses: \(store.money(expenses))", font: .boldSystemFont(ofSize: 16), color: .systemRed)
            draw("Net: \(store.money(income - expenses))", font: .boldSystemFont(ofSize: 16))
            y += 10
            draw("Transactions", font: .boldSystemFont(ofSize: 18))
            for item in transactions {
                let account = store.account(for: item.accountID)
                draw("\(item.date.formatted(date: .abbreviated, time: .omitted))  ·  \(item.category)  ·  \(item.kind.rawValue)  ·  \(store.money(item.amount, currency: account?.currency ?? store.mainCurrency))", font: .systemFont(ofSize: 11))
            }
        }
        pdfURL = url
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "location.north.circle.fill")
                .font(.system(size: 68))
                .foregroundStyle(.teal)

            Text("Nomad Wealth")
                .font(.largeTitle.bold())

            Text("Native personal finance for accounts, budgets, investments, loans and travel.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Text("Developed by Hafizuddin")
                .font(.footnote)
        }
        .padding()
        .navigationTitle("About")
    }
}

struct AnalyticsView: View {
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SectionCard(title: "Income vs expense") {
                    Chart {
                        BarMark(
                            x: .value("Type", "Income"),
                            y: .value("Amount", store.currentMonthTotal(.income))
                        )
                        .foregroundStyle(.green)

                        BarMark(
                            x: .value("Type", "Expense"),
                            y: .value("Amount", store.currentMonthTotal(.expense))
                        )
                        .foregroundStyle(.red)
                    }
                    .frame(height: 240)
                }

                SectionCard(title: "Investment performance") {
                    Chart(store.investments) { item in
                        BarMark(
                            x: .value("Investment", item.name),
                            y: .value("Current value", item.currentValue)
                        )
                        .foregroundStyle(.teal)
                    }
                    .frame(height: 220)
                }
            }
            .padding()
        }
        .navigationTitle("Analytics")
    }
}
