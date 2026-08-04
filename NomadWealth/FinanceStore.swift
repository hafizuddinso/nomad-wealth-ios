import Foundation
import SwiftUI

@MainActor
final class FinanceStore: ObservableObject {
    static let expenseCategories = ["Housing", "Groceries", "Food", "Transport", "Travel", "Utilities", "Health", "Education", "Shopping", "Entertainment", "Subscriptions", "Insurance", "Loan Repayment", "Family", "Business", "Other"]
    static let incomeCategories = ["Salary", "Freelance", "Business", "Investment Income", "Gift", "Refund", "Other"]

    @Published var profile = UserProfile()
    @Published var signedIn = false
    @Published var appearance = Appearance.system
    @Published var appFont = AppFont.modern
    @Published var mainCurrency = "EUR"
    @Published var millionCurrency = "EUR"
    @Published var accounts: [Account] = []
    @Published var transactions: [FinanceTransaction] = []
    @Published var budgets: [Budget] = []
    @Published var investments: [Investment] = []
    @Published var travelPlans: [TravelPlan] = []
    @Published var loans: [Loan] = []
    @Published var accountAdjustments: [AccountAdjustmentRecord] = []

    private let storageKey = "NomadWealthNativeStateV2"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() { load() }
    var selectedFontDesign: Font.Design { appFont.design }

    func signUp(name: String, email: String, password: String) async throws {
        let user = try await SupabaseAuthService.shared.signUp(name: name, email: email, password: password)
        if let user {
            profile.name = user.displayName
            profile.email = user.email ?? email
            signedIn = true
            save()
        }
    }

    func logIn(email: String, password: String) async throws {
        let session = try await SupabaseAuthService.shared.signIn(email: email, password: password)
        profile.name = session.user.displayName
        profile.email = session.user.email ?? email
        signedIn = true
        save()
    }

    func logOut() { SupabaseAuthService.shared.signOut(); signedIn = false; save() }

    func balance(for account: Account) -> Double {
        account.openingBalance + transactions.filter { $0.accountID == account.id }.reduce(0) { $0 + ($1.kind == .income ? $1.amount : -$1.amount) }
    }

    func addTransaction(_ item: FinanceTransaction) { transactions.append(item); transactions.sort { $0.date > $1.date }; save() }

    func recordAccountAdjustment(account: Account, type: String, amount: Double, previousBalance: Double, newBalance: Double, note: String = "") {
        accountAdjustments.insert(
            AccountAdjustmentRecord(
                accountID: account.id,
                type: type,
                amount: amount,
                previousBalance: previousBalance,
                newBalance: newBalance,
                date: Date(),
                note: note
            ),
            at: 0
        )
        save()
    }

    func transactions(for accountID: UUID) -> [FinanceTransaction] {
        transactions.filter { $0.accountID == accountID }.sorted { $0.date > $1.date }
    }

    func adjustments(for accountID: UUID) -> [AccountAdjustmentRecord] {
        accountAdjustments.filter { $0.accountID == accountID }.sorted { $0.date > $1.date }
    }

    func resetFinancialData() {
        accounts = []
        transactions = []
        budgets = []
        investments = []
        travelPlans = []
        loans = []
        accountAdjustments = []
        save()
    }
    func deleteTransaction(_ item: FinanceTransaction) { transactions.removeAll { $0.id == item.id }; save() }
    func account(for id: UUID) -> Account? { accounts.first { $0.id == id } }

    func currentMonthTotal(_ kind: TransactionKind) -> Double {
        let calendar = Calendar.current
        return transactions.filter { $0.kind == kind && calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + convertedToMain($1.amount, from: account(for: $1.accountID)?.currency ?? mainCurrency) }
    }

    func spent(for budget: Budget) -> Double {
        let calendar = Calendar.current
        return transactions.filter { item in
            guard item.kind == .expense, item.category == budget.category else { return false }
            if let accountID = budget.accountID, item.accountID != accountID { return false }
            switch budget.period {
            case .weekly: return calendar.isDate(item.date, equalTo: budget.startDate, toGranularity: .weekOfYear)
            case .monthly: return calendar.isDate(item.date, equalTo: budget.startDate, toGranularity: .month)
            case .yearly: return calendar.isDate(item.date, equalTo: budget.startDate, toGranularity: .year)
            }
        }.reduce(0) { $0 + $1.amount }
    }

    func travelSpent(_ plan: TravelPlan) -> Double {
        transactions.filter { item in
            item.kind == .expense && item.date >= plan.startDate && item.date <= plan.endDate && (plan.accountID == nil || item.accountID == plan.accountID)
        }.reduce(0) { $0 + $1.amount }
    }

    func convertedToMain(_ amount: Double, from currency: String) -> Double {
        let euroRates: [String: Double] = ["EUR": 1, "USD": 1.09, "GBP": 0.85, "RUB": 96, "BDT": 128, "ALL": 100, "CAD": 1.48, "AUD": 1.66]
        return amount / (euroRates[currency] ?? 1) * (euroRates[mainCurrency] ?? 1)
    }

    func convert(_ amount: Double, from: String, to: String) -> Double {
        let euroRates: [String: Double] = ["EUR": 1, "USD": 1.09, "GBP": 0.85, "RUB": 96, "BDT": 128, "ALL": 100, "CAD": 1.48, "AUD": 1.66]
        return amount / (euroRates[from] ?? 1) * (euroRates[to] ?? 1)
    }

    func money(_ value: Double, currency: String? = nil) -> String {
        let formatter = NumberFormatter(); formatter.numberStyle = .currency; formatter.currencyCode = currency ?? mainCurrency; formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    func calculatedInstallment(principal: Double, annualRate: Double, months: Int) -> Double {
        let n = Double(max(months, 1)); let r = max(annualRate, 0) / 100 / 12
        guard principal > 0 else { return 0 }; if r == 0 { return principal / n }
        let factor = pow(1 + r, n); return principal * r * factor / (factor - 1)
    }

    func recordPayment(loanID: UUID, amount: Double, extraPayment: Double = 0, date: Date) {
        guard let index = loans.firstIndex(where: { $0.id == loanID }) else { return }
        let loan = loans[index]; let monthlyRate = loan.annualRate / 100 / 12
        let interest = min(amount, loan.remainingPrincipal * monthlyRate); let principal = max(0, amount - interest)
        loans[index].payments.append(LoanPayment(date: date, amount: amount, principal: principal, interest: interest, extraPayment: extraPayment))
        loans[index].nextPaymentDate = Calendar.current.date(byAdding: .month, value: 1, to: date) ?? date
        if let accountID = loan.accountID {
            addTransaction(FinanceTransaction(kind: .expense, accountID: accountID, amount: amount + extraPayment, category: "Loan Repayment", note: "Repayment: \(loan.name)", date: date))
        } else { save() }
    }

    func save() {
        let state = PersistedState(profile: profile, signedIn: signedIn, appearance: appearance, appFont: appFont, mainCurrency: mainCurrency, millionCurrency: millionCurrency, accounts: accounts, transactions: transactions, budgets: budgets, investments: investments, travelPlans: travelPlans, loans: loans, accountAdjustments: accountAdjustments)
        if let data = try? encoder.encode(state) { UserDefaults.standard.set(data, forKey: storageKey) }
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey), let state = try? decoder.decode(PersistedState.self, from: data) else { return }
        profile = state.profile; signedIn = state.signedIn; appearance = state.appearance; appFont = state.appFont; mainCurrency = state.mainCurrency; millionCurrency = state.millionCurrency
        accounts = state.accounts; transactions = state.transactions.sorted { $0.date > $1.date }; budgets = state.budgets; investments = state.investments; travelPlans = state.travelPlans; loans = state.loans; accountAdjustments = state.accountAdjustments ?? []
    }
}
