import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var kind: TransactionKind?

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Button { AppHaptics.impact(); kind = .income } label: {
                        Label("Money In", systemImage: "arrow.down").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(.green)

                    Button { AppHaptics.impact(); kind = .expense } label: {
                        Label("Money Out", systemImage: "arrow.up").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(.red)
                }
            }

            if !store.travelPlans.isEmpty {
                Section("Travel plans") {
                    ForEach(store.travelPlans) { plan in
                        NavigationLink { TravelModeView() } label: {
                            HStack {
                                Image(systemName: "airplane.circle.fill").foregroundStyle(.teal)
                                VStack(alignment: .leading) {
                                    Text(plan.name).font(.headline)
                                    Text("\(plan.destination) · Left \(store.money(max(0, plan.budget - store.travelSpent(plan)), currency: plan.currency))")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            Section("Transactions") {
                if store.transactions.isEmpty {
                    EmptyMessage(icon: "arrow.left.arrow.right.circle", title: "No transactions yet", message: "Add money in or money out.")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(store.transactions) { item in TransactionRow(item: item) }
                        .onDelete { offsets in
                            let items = offsets.map { store.transactions[$0] }
                            items.forEach(store.deleteTransaction)
                        }
                }
            }
        }
        .navigationTitle("Transactions")
        .sheet(item: $kind) { TransactionFormView(kind: $0) }
    }
}

struct TransactionRow: View {
    @EnvironmentObject private var store: FinanceStore
    let item: FinanceTransaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.kind == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.title2).foregroundStyle(item.kind == .income ? Color.green : Color.red)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.kind == .income ? "Money in" : "Money out").font(.caption.bold())
                    .foregroundStyle(item.kind == .income ? Color.green : Color.red)
                Text(item.category).font(.headline)
                Text("\(store.account(for: item.accountID)?.name ?? "Unlinked") · \(item.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(item.kind == .income ? "+" : "−")\(store.money(item.amount, currency: store.account(for: item.accountID)?.currency ?? store.mainCurrency))")
                .fontWeight(.semibold).foregroundStyle(item.kind == .income ? Color.green : Color.red)
        }
    }
}

struct TransactionFormView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    let kind: TransactionKind

    @State private var accountID: UUID?
    @State private var amountText = ""
    @State private var category = ""
    @State private var note = ""
    @State private var date = Date()

    private var categories: [String] { kind == .income ? FinanceStore.incomeCategories : FinanceStore.expenseCategories }
    private var amount: Double? { Double(amountText.replacingOccurrences(of: ",", with: ".")) }

    var body: some View {
        NavigationView {
            Form {
                if store.accounts.isEmpty {
                    Text("Add an account before recording a transaction.").foregroundStyle(.red)
                } else {
                    Picker(kind == .income ? "Select receiving account" : "Select payment account", selection: $accountID) {
                        Text("Select account").tag(UUID?.none)
                        ForEach(store.accounts.filter { $0.type != .debt }) { account in
                            Text("\(account.name) · \(account.currency)").tag(Optional(account.id))
                        }
                    }

                    TextField("Enter amount", text: $amountText).keyboardType(.decimalPad)

                    Picker(kind == .income ? "Select income source" : "Select expense category", selection: $category) {
                        Text("Select category").tag("")
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Add a note (optional)", text: $note)
                }
            }
            .navigationTitle(kind == .income ? "Money In" : "Money Out")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let accountID, let amount, amount > 0, !category.isEmpty else { return }
                        store.addTransaction(FinanceTransaction(kind: kind, accountID: accountID, amount: amount, category: category, note: note, date: date))
                        AppHaptics.success(); dismiss()
                    }
                    .disabled(accountID == nil || (amount ?? 0) <= 0 || category.isEmpty)
                }
            }
        }
    }
}
