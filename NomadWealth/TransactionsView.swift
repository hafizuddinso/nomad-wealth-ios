import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var kind: TransactionKind?

    var body: some View {
        List {
            Section {
                HStack {
                    Button {
                        AppHaptics.impact()
                        kind = .income
                    } label: {
                        Label("Money In", systemImage: "arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Button {
                        AppHaptics.impact()
                        kind = .expense
                    } label: {
                        Label("Money Out", systemImage: "arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }

            if store.transactions.isEmpty {
                EmptyMessage(
                    icon: "arrow.left.arrow.right.circle",
                    title: "No transactions yet",
                    message: "Add money in or money out."
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(store.transactions) { item in
                    TransactionRow(item: item)
                }
                .onDelete { offsets in
                    let items = offsets.map { store.transactions[$0] }
                    items.forEach(store.deleteTransaction)
                }
            }
        }
        .navigationTitle("Transactions")
        .sheet(item: $kind) { kind in
            TransactionFormView(kind: kind)
        }
    }
}

struct TransactionRow: View {
    @EnvironmentObject private var store: FinanceStore
    let item: FinanceTransaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.kind == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.title2)
                .foregroundStyle(item.kind == .income ? .green : .red)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.kind == .income ? "Money in" : "Money out")
                    .font(.caption.bold())
                    .foregroundStyle(item.kind == .income ? .green : .red)
                Text(item.category).font(.headline)
                Text("\(store.account(for: item.accountID)?.name ?? "Unlinked") · \(item.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            let currency = store.account(for: item.accountID)?.currency ?? store.mainCurrency
            Text("\(item.kind == .income ? "+" : "−")\(store.money(item.amount, currency: currency))")
                .fontWeight(.semibold)
                .foregroundStyle(item.kind == .income ? .green : .red)
        }
    }
}

struct TransactionFormView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    let kind: TransactionKind

    @State private var accountID: UUID?
    @State private var amount = 0.0
    @State private var category = ""
    @State private var note = ""
    @State private var date = Date()

    private var categories: [String] {
        kind == .income
        ? ["Salary", "Freelance", "Business", "Bonus", "Investment income", "Gift", "Refund", "Other income"]
        : ["Housing", "Food", "Groceries", "Transport", "Utilities", "Health", "Shopping", "Travel", "Loan payment", "Other expense"]
    }

    var body: some View {
        NavigationView {
            Form {
                if store.accounts.isEmpty {
                    Text("Add an account before recording a transaction.")
                        .foregroundStyle(.red)
                } else {
                    Picker(kind == .income ? "Which account received it?" : "Which account did you pay from?", selection: $accountID) {
                        ForEach(store.accounts.filter { $0.type != .debt }) { account in
                            Text("\(account.name) · \(account.currency)")
                                .tag(Optional(account.id))
                        }
                    }

                    if let id = accountID, let account = store.account(for: id) {
                        LabeledContent("Currency", value: account.currency)
                    }

                    TextField("Amount", value: $amount, format: .number)
                        .keyboardType(.decimalPad)

                    Picker(kind == .income ? "Income source" : "Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Note", text: $note)
                }
            }
            .navigationTitle(kind == .income ? "Money In" : "Money Out")
            .onAppear {
                accountID = store.accounts.first(where: { $0.type != .debt })?.id
                category = categories.first ?? ""
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let accountID, amount > 0 else { return }
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                            store.addTransaction(
                                FinanceTransaction(
                                    kind: kind,
                                    accountID: accountID,
                                    amount: amount,
                                    category: category,
                                    note: note,
                                    date: date
                                )
                            )
                        }
                        AppHaptics.success()
                        dismiss()
                    }
                    .disabled(accountID == nil || amount <= 0)
                }
            }
        }
    }
}
