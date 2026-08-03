import Foundation
import SwiftUI

@MainActor
final class FinanceStore: ObservableObject {
    @Published var profile = UserProfile()
    @Published var signedIn = false
    @Published var appearance = Appearance.system
    @Published var appFont = AppFont.modern
    @Published var mainCurrency = "EUR"
    @Published var millionCurrency = "EUR"
    @Published var accounts: [Account] = []
    @Published var transactions: [FinanceTransaction] = []
    @Published var budgets: [Budget] = []
    @Published var loans: [Loan] = []

    private let storageKey = "NomadWealthNativeStateV1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        load()
    }

    var selectedFontDesign: Font.Design { appFont.design }

    func signUp(name: String, email: String, password: String) async throws {
        let user = try await SupabaseAuthService.shared.signUp(
            name: name,
            email: email,
            password: password
        )

        if let user {
            profile = UserProfile(
                name: user.displayName,
                email: user.email ?? email,
                password: ""
            )
            signedIn = true
            save()
        }
    }

    func logIn(email: String, password: String) async throws {
        let session = try await SupabaseAuthService.shared.signIn(
            email: email,
            password: password
        )

        profile = UserProfile(
            name: session.user.displayName,
            email: session.user.email ?? email,
            password: ""
        )

        signedIn = true
        save()
    }

    func logOut() {
        SupabaseAuthService.shared.signOut()
        signedIn = false
        save()
    }

    func balance(for account: Account) -> Double {
        let movement = transactions
            .filter { $0.accountID == account.id }
            .reduce(0.0) { partial, item in
                partial + (item.kind == .income ? item.amount : -item.amount)
            }
        return account.openingBalance + movement
    }

    func addTransaction(_ item: FinanceTransaction) {
        transactions.append(item)
        transactions.sort { $0.date > $1.date }
        save()
    }

    func deleteTransaction(_ item: FinanceTransaction) {
        transactions.removeAll { $0.id == item.id }
        save()
    }

    func currentMonthTotal(_ kind: TransactionKind) -> Double {
        let calendar = Calendar.current
        return transactions
            .filter { $0.kind == kind && calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + convertedToMain($1.amount, from: account(for: $1.accountID)?.currency ?? mainCurrency) }
    }

    func account(for id: UUID) -> Account? {
        accounts.first { $0.id == id }
    }

    func convertedToMain(_ amount: Double, from currency: String) -> Double {
        // Offline reference rates. A future release can replace these with live rates.
        let euroRates: [String: Double] = [
            "EUR": 1, "USD": 1.09, "GBP": 0.85, "RUB": 96,
            "BDT": 128, "ALL": 100, "CAD": 1.48, "AUD": 1.66
        ]
        let fromRate = euroRates[currency] ?? 1
        let toRate = euroRates[mainCurrency] ?? 1
        return amount / fromRate * toRate
    }

    func money(_ value: Double, currency: String? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency ?? mainCurrency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    func calculatedInstallment(principal: Double, annualRate: Double, months: Int) -> Double {
        let n = Double(max(months, 1))
        let r = max(annualRate, 0) / 100 / 12
        guard principal > 0 else { return 0 }
        if r == 0 { return principal / n }
        let factor = pow(1 + r, n)
        return principal * r * factor / (factor - 1)
    }

    func recordPayment(loanID: UUID, amount: Double, date: Date) {
        guard let index = loans.firstIndex(where: { $0.id == loanID }) else { return }
        let loan = loans[index]
        let monthlyRate = loan.annualRate / 100 / 12
        let interest = min(amount, loan.remainingPrincipal * monthlyRate)
        let principal = max(0, amount - interest)
        loans[index].payments.append(
            LoanPayment(date: date, amount: amount, principal: principal, interest: interest)
        )
        loans[index].nextPaymentDate = Calendar.current.date(byAdding: .month, value: 1, to: date) ?? date
        save()
    }

    func save() {
        let state = PersistedState(
            profile: profile,
            signedIn: signedIn,
            appearance: appearance,
            appFont: appFont,
            mainCurrency: mainCurrency,
            millionCurrency: millionCurrency,
            accounts: accounts,
            transactions: transactions,
            budgets: budgets,
            loans: loans
        )
        guard let data = try? encoder.encode(state) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let state = try? decoder.decode(PersistedState.self, from: data) else { return }
        profile = state.profile
        signedIn = state.signedIn
        appearance = state.appearance
        appFont = state.appFont
        mainCurrency = state.mainCurrency
        millionCurrency = state.millionCurrency
        accounts = state.accounts
        transactions = state.transactions.sorted { $0.date > $1.date }
        budgets = state.budgets
        loans = state.loans
    }
}
