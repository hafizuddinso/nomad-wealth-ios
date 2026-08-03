import SwiftUI

struct AccountsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showAdd = false
    @State private var adjustmentAccount: Account?

    var body: some View {
        List {
            if store.accounts.isEmpty {
                EmptyMessage(
                    icon: "creditcard.circle",
                    title: "No accounts yet",
                    message: "Add your first account to start tracking balances."
                )
                .listRowBackground(Color.clear)
            }

            ForEach(store.accounts) { account in
                Button {
                    adjustmentAccount = account
                } label: {
                    HStack {
                        Image(systemName: account.type == .cash ? "banknote" : "creditcard")
                            .foregroundStyle(.teal)
                        VStack(alignment: .leading) {
                            Text(account.name).font(.headline).foregroundStyle(.primary)
                            Text("\(account.institution) · \(account.type.rawValue) · \(account.currency)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(store.money(store.balance(for: account), currency: account.currency))
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .onDelete { offsets in
                store.accounts.remove(atOffsets: offsets)
                store.save()
            }
        }
        .navigationTitle("Accounts")
        .toolbar {
            Button {
                AppHaptics.impact()
                showAdd = true
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
        .sheet(isPresented: $showAdd) {
            AccountFormView()
        }
        .sheet(item: $adjustmentAccount) { account in
            AccountAdjustmentView(account: account)
        }
    }
}

struct AccountFormView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var institution = ""
    @State private var type = AccountType.bank
    @State private var currency = "EUR"
    @State private var balance = 0.0

    let currencies = ["EUR", "USD", "GBP", "RUB", "BDT", "ALL", "CAD", "AUD"]

    var body: some View {
        NavigationView {
            Form {
                TextField("Account name", text: $name)
                TextField("Bank or institution", text: $institution)
                Picker("Type", selection: $type) {
                    ForEach(AccountType.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Currency", selection: $currency) {
                    ForEach(currencies, id: \.self) { Text($0).tag($0) }
                }
                TextField("Opening balance", value: $balance, format: .number)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Add account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.accounts.append(
                            Account(
                                name: name.isEmpty ? "Account" : name,
                                institution: institution,
                                type: type,
                                currency: currency,
                                openingBalance: balance
                            )
                        )
                        store.save()
                        AppHaptics.success()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AccountAdjustmentView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    let account: Account
    @State private var mode = "Correction"
    @State private var amount = 0.0

    var body: some View {
        NavigationView {
            Form {
                Section("Current balance") {
                    Text(store.money(store.balance(for: account), currency: account.currency))
                        .font(.title2.bold())
                }

                Picker("Action", selection: $mode) {
                    Text("Correction").tag("Correction")
                    Text("Deposit").tag("Deposit")
                    Text("Withdrawal").tag("Withdrawal")
                }

                TextField("Amount", value: $amount, format: .number)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Adjust balance")
            .onAppear {
                amount = store.balance(for: account)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        apply()
                        dismiss()
                    }
                }
            }
        }
    }

    private func apply() {
        if mode == "Correction" {
            guard let index = store.accounts.firstIndex(where: { $0.id == account.id }) else { return }
            let difference = amount - store.balance(for: account)
            store.accounts[index].openingBalance += difference
            store.save()
            AppHaptics.success()
            return
        }

        AppHaptics.success()
        store.addTransaction(
            FinanceTransaction(
                kind: mode == "Deposit" ? .income : .expense,
                accountID: account.id,
                amount: amount,
                category: mode,
                note: "Balance adjustment",
                date: Date()
            )
        )
    }
}
