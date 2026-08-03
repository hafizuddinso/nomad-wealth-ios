import SwiftUI
import Charts

struct LoansView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showAdd = false
    @State private var paymentLoan: Loan?

    var body: some View {
        List {
            if store.loans.isEmpty {
                EmptyMessage(
                    icon: "building.columns.circle",
                    title: "No loans yet",
                    message: "Add a loan to track principal, interest and installments."
                )
                .listRowBackground(Color.clear)
            }

            ForEach(store.loans) { loan in
                Button {
                    paymentLoan = loan
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(loan.name).font(.headline).foregroundStyle(.primary)
                                Text("\(loan.lender) · \(loan.currency)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(store.money(loan.remainingPrincipal, currency: loan.currency))
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }

                        ProgressView(value: loan.principal == 0 ? 0 : loan.principalPaid / loan.principal)
                            .tint(.teal)

                        HStack {
                            Label("Installment \(store.money(loan.installment, currency: loan.currency))", systemImage: "calendar")
                            Spacer()
                            Text("Paid \(store.money(loan.totalPaid, currency: loan.currency))")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            }
            .onDelete { offsets in
                store.loans.remove(atOffsets: offsets)
                store.save()
            }
        }
        .navigationTitle("Loans")
        .toolbar {
            Button {
                AppHaptics.impact()
                showAdd = true
            } label: {
                Label("Add loan", systemImage: "plus")
            }
        }
        .sheet(isPresented: $showAdd) {
            LoanFormView()
        }
        .sheet(item: $paymentLoan) { loan in
            LoanDetailView(loanID: loan.id)
        }
    }
}

struct LoanFormView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var lender = ""
    @State private var currency = "EUR"
    @State private var principal = 0.0
    @State private var annualRate = 0.0
    @State private var termMonths = 12
    @State private var startDate = Date()
    @State private var nextPaymentDate = Date()

    private var installment: Double {
        store.calculatedInstallment(
            principal: principal,
            annualRate: annualRate,
            months: termMonths
        )
    }

    private var totalPayable: Double {
        installment * Double(max(termMonths, 1))
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Loan") {
                    TextField("Loan name", text: $name)
                    TextField("Lender", text: $lender)
                    Picker("Currency", selection: $currency) {
                        ForEach(["EUR","USD","GBP","RUB","BDT","ALL","CAD","AUD"], id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                }

                Section("Terms") {
                    TextField("Original principal", value: $principal, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Annual interest rate (%)", value: $annualRate, format: .number)
                        .keyboardType(.decimalPad)
                    Stepper("Loan term: \(termMonths) months", value: $termMonths, in: 1...600)
                    DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                    DatePicker("Next payment", selection: $nextPaymentDate, displayedComponents: .date)
                }

                Section("Automatic estimate") {
                    LabeledContent("Monthly installment", value: store.money(installment, currency: currency))
                    LabeledContent("Total payable", value: store.money(totalPayable, currency: currency))
                    LabeledContent("Estimated interest", value: store.money(max(0, totalPayable - principal), currency: currency))
                    LabeledContent("Installments", value: "\(termMonths)")
                }

                Section {
                    Text("Estimate uses a reducing-balance formula. Your lender may calculate fees or interest differently.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add a loan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.loans.append(
                            Loan(
                                name: name.isEmpty ? "Loan" : name,
                                lender: lender,
                                currency: currency,
                                principal: principal,
                                annualRate: annualRate,
                                termMonths: termMonths,
                                installment: installment,
                                startDate: startDate,
                                nextPaymentDate: nextPaymentDate
                            )
                        )
                        store.save()
                        AppHaptics.success()
                        dismiss()
                    }
                    .disabled(principal <= 0)
                }
            }
        }
    }
}

struct LoanDetailView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    let loanID: UUID
    @State private var amount = 0.0
    @State private var date = Date()

    private var loan: Loan? {
        store.loans.first { $0.id == loanID }
    }

    var body: some View {
        NavigationView {
            Form {
                if let loan {
                    Section("Overview") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Repayment progress")
                                .font(.headline)
                            Chart {
                                BarMark(
                                    x: .value("Type", "Paid"),
                                    y: .value("Amount", loan.principalPaid)
                                )
                                .foregroundStyle(.teal)

                                BarMark(
                                    x: .value("Type", "Remaining"),
                                    y: .value("Amount", loan.remainingPrincipal)
                                )
                                .foregroundStyle(.orange)
                            }
                            .frame(height: 170)
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                        }

                        LabeledContent("Original principal", value: store.money(loan.principal, currency: loan.currency))
                        LabeledContent("Principal remaining", value: store.money(loan.remainingPrincipal, currency: loan.currency))
                        LabeledContent("Interest paid", value: store.money(loan.interestPaid, currency: loan.currency))
                        LabeledContent("Total paid", value: store.money(loan.totalPaid, currency: loan.currency))
                        LabeledContent("Next payment", value: loan.nextPaymentDate.formatted(date: .abbreviated, time: .omitted))
                    }

                    Section("Record installment") {
                        TextField("Amount", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                        Button("Record payment") {
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                                store.recordPayment(loanID: loanID, amount: amount, date: date)
                                amount = 0
                            }
                            AppHaptics.success()
                        }
                        .disabled(amount <= 0)
                    }

                    Section("Payment history") {
                        if loan.payments.isEmpty {
                            Text("No payments recorded.")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(loan.payments.sorted { $0.date > $1.date }) { payment in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(payment.date.formatted(date: .abbreviated, time: .omitted))
                                    Spacer()
                                    Text(store.money(payment.amount, currency: loan.currency)).bold()
                                }
                                Text("Principal \(store.money(payment.principal, currency: loan.currency)) · Interest \(store.money(payment.interest, currency: loan.currency))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(loan?.name ?? "Loan")
            .toolbar {
                Button("Done") { dismiss() }
            }
            .onAppear {
                amount = loan?.installment ?? 0
            }
        }
    }
}
