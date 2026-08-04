import SwiftUI

struct AccountsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showAdd = false
    @State private var selectedAccount: Account?

    var body: some View {
        List {
            if store.accounts.isEmpty {
                EmptyMessage(icon: "creditcard.circle", title: "No accounts yet", message: "Add a bank, cash, savings or wallet account.")
                    .listRowBackground(Color.clear)
                Section {
                    centeredAddButton
                }
            } else {
                ForEach(store.accounts) { account in
                    Button { selectedAccount = account } label: {
                        HStack {
                            Image(systemName: account.type == .cash ? "banknote" : "building.columns")
                                .foregroundStyle(.teal)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(account.name).font(.headline).foregroundStyle(.primary)
                                Text("\(account.institution.isEmpty ? "Institution not added" : account.institution) · \(account.currency)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(store.money(store.balance(for: account), currency: account.currency))
                                .fontWeight(.semibold).foregroundStyle(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in store.accounts.remove(atOffsets: offsets); store.save() }

                Section { centeredAddButton }
            }
        }
        .navigationTitle("Accounts")
        .toolbar {
            Button { AppHaptics.impact(); showAdd = true } label: { Label("Add", systemImage: "plus") }
        }
        .sheet(isPresented: $showAdd) { AccountFormView() }
        .sheet(item: $selectedAccount) { AccountDetailView(account: $0) }
    }

    private var centeredAddButton: some View {
        Button { AppHaptics.impact(); showAdd = true } label: {
            Label("Add account", systemImage: "plus.circle.fill")
                .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
        }.buttonStyle(.borderedProminent)
    }
}

struct AccountFormView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var institution = ""
    @State private var type: AccountType?
    @State private var currency = ""
    @State private var balanceText = ""

    private let currencies = ["EUR", "USD", "GBP", "RUB", "BDT", "ALL", "CAD", "AUD"]
    private let banksByCurrency: [String: [String]] = [
        "RUB": ["Sberbank", "T-Bank", "VTB", "Alfa-Bank", "Gazprombank", "Raiffeisenbank", "Ozon Bank", "Other Russian bank"],
        "BDT": ["Dutch-Bangla Bank", "BRAC Bank", "City Bank", "Eastern Bank", "Islami Bank Bangladesh", "Prime Bank", "Sonali Bank", "Agrani Bank", "Other Bangladeshi bank"],
        "EUR": ["Revolut", "Wise", "N26", "Raiffeisen Bank", "UniCredit", "Intesa Sanpaolo", "Other European bank"],
        "USD": ["Chase", "Bank of America", "Wells Fargo", "Citibank", "Capital One", "Wise", "Other bank"],
        "GBP": ["Barclays", "HSBC", "Lloyds Bank", "NatWest", "Monzo", "Starling Bank", "Other UK bank"],
        "ALL": ["BKT", "Credins Bank", "Raiffeisen Bank Albania", "OTP Bank Albania", "Intesa Sanpaolo Albania", "Other Albanian bank"]
    ]

    private var availableBanks: [String] { banksByCurrency[currency] ?? ["Other bank or institution"] }

    var body: some View {
        NavigationView {
            Form {
                Section("Account information") {
                    TextField("Account name", text: $name)
                    Picker("Currency", selection: $currency) {
                        Text("Select currency").tag("")
                        ForEach(currencies, id: \.self) { Text($0).tag($0) }
                    }
                    .onChange(of: currency) { _ in institution = "" }

                    if !currency.isEmpty {
                        Picker("Bank or financial institution", selection: $institution) {
                            Text("Select institution").tag("")
                            ForEach(availableBanks, id: \.self) { Text($0).tag($0) }
                        }
                    }

                    Picker("Account type", selection: $type) {
                        Text("Select account type").tag(AccountType?.none)
                        ForEach(AccountType.allCases) { Text($0.rawValue).tag(Optional($0)) }
                    }
                    TextField("Opening balance", text: $balanceText).keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let type, !name.trimmingCharacters(in: .whitespaces).isEmpty, !institution.isEmpty, !currency.isEmpty else { return }
                        store.accounts.append(Account(name: name.trimmingCharacters(in: .whitespaces), institution: institution, type: type, currency: currency, openingBalance: Double(balanceText.replacingOccurrences(of: ",", with: ".")) ?? 0))
                        store.save(); AppHaptics.success(); dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || institution.isEmpty || type == nil || currency.isEmpty)
                }
            }
        }
    }
}

struct AccountDetailView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    let account: Account
    @State private var showAdjustment = false

    var body: some View {
        NavigationView {
            List {
                Section("Account summary") {
                    LabeledContent("Account", value: account.name)
                    LabeledContent("Institution", value: account.institution)
                    LabeledContent("Currency", value: account.currency)
                    LabeledContent("Current balance", value: store.money(store.balance(for: account), currency: account.currency))
                    Button("Modify balance") { showAdjustment = true }
                }

                Section("Recent balance changes") {
                    if store.adjustments(for: account.id).isEmpty {
                        Text("No manual balance changes yet.").foregroundStyle(.secondary)
                    } else {
                        ForEach(store.adjustments(for: account.id).prefix(10)) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack { Text(item.type).font(.headline); Spacer(); Text(item.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary) }
                                Text("\(store.money(item.previousBalance, currency: account.currency)) → \(store.money(item.newBalance, currency: account.currency))")
                                if !item.note.isEmpty { Text(item.note).font(.caption).foregroundStyle(.secondary) }
                            }
                        }
                    }
                }

                Section("Transactions from this account") {
                    let items = store.transactions(for: account.id)
                    if items.isEmpty { Text("No transactions yet.").foregroundStyle(.secondary) }
                    else { ForEach(items) { TransactionRow(item: $0) } }
                }
            }
            .navigationTitle(account.name)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showAdjustment) { AccountAdjustmentView(account: account) }
        }
    }
}

struct AccountAdjustmentView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    let account: Account
    @State private var mode = ""
    @State private var amountText = ""
    @State private var note = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Current balance") { Text(store.money(store.balance(for: account), currency: account.currency)).font(.title2.bold()) }
                Picker("Action", selection: $mode) {
                    Text("Select action").tag("")
                    Text("Set exact balance").tag("Correction")
                    Text("Add money").tag("Deposit")
                    Text("Remove money").tag("Withdrawal")
                }
                TextField("Enter amount", text: $amountText).keyboardType(.decimalPad)
                TextField("Reason or note", text: $note)
            }
            .navigationTitle("Modify balance")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { apply(); dismiss() }
                        .disabled(mode.isEmpty || (Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? -1) < 0)
                }
            }
        }
    }

    private func apply() {
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")) else { return }
        let previous = store.balance(for: account)
        var newBalance = previous
        if mode == "Correction" {
            guard let index = store.accounts.firstIndex(where: { $0.id == account.id }) else { return }
            store.accounts[index].openingBalance += amount - previous
            newBalance = amount
            store.recordAccountAdjustment(account: account, type: "Balance corrected", amount: amount, previousBalance: previous, newBalance: newBalance, note: note)
        } else {
            newBalance = mode == "Deposit" ? previous + amount : previous - amount
            store.addTransaction(FinanceTransaction(kind: mode == "Deposit" ? .income : .expense, accountID: account.id, amount: amount, category: mode, note: note.isEmpty ? "Balance adjustment" : note, date: Date()))
            store.recordAccountAdjustment(account: account, type: mode == "Deposit" ? "Money added" : "Money removed", amount: amount, previousBalance: previous, newBalance: newBalance, note: note)
        }
        AppHaptics.success()
    }
}
