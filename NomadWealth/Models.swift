import Foundation
import SwiftUI

enum Appearance: String, Codable, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AppFont: String, Codable, CaseIterable, Identifiable {
    case modern, system, rounded, serif, mono
    var id: String { rawValue }

    var title: String {
        switch self {
        case .modern: return "Modern"
        case .system: return "System"
        case .rounded: return "Rounded"
        case .serif: return "Serif"
        case .mono: return "Mono"
        }
    }

    var design: Font.Design {
        switch self {
        case .modern, .system: return .default
        case .rounded: return .rounded
        case .serif: return .serif
        case .mono: return .monospaced
        }
    }
}

enum AccountType: String, Codable, CaseIterable, Identifiable {
    case bank = "Bank"
    case cash = "Cash"
    case savings = "Savings"
    case wallet = "Wallet"
    case debt = "Debt"
    var id: String { rawValue }
}

enum TransactionKind: String, Codable, CaseIterable, Identifiable {
    case expense = "Expense"
    case income = "Income"
    var id: String { rawValue }
}

struct UserProfile: Codable {
    var name: String = ""
    var email: String = ""
    var password: String = ""
}

struct Account: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var institution: String
    var type: AccountType
    var currency: String
    var openingBalance: Double
}

struct FinanceTransaction: Identifiable, Codable, Hashable {
    var id = UUID()
    var kind: TransactionKind
    var accountID: UUID
    var amount: Double
    var category: String
    var note: String
    var date: Date
}

struct Budget: Identifiable, Codable, Hashable {
    var id = UUID()
    var category: String
    var limit: Double
    var currency: String
}

struct LoanPayment: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date
    var amount: Double
    var principal: Double
    var interest: Double
}

struct Loan: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var lender: String
    var currency: String
    var principal: Double
    var annualRate: Double
    var termMonths: Int
    var installment: Double
    var startDate: Date
    var nextPaymentDate: Date
    var payments: [LoanPayment] = []

    var totalPaid: Double {
        payments.reduce(0) { $0 + $1.amount }
    }

    var principalPaid: Double {
        payments.reduce(0) { $0 + $1.principal }
    }

    var interestPaid: Double {
        payments.reduce(0) { $0 + $1.interest }
    }

    var remainingPrincipal: Double {
        max(0, principal - principalPaid)
    }

    var estimatedTotalPayable: Double {
        installment * Double(max(termMonths, 1))
    }

    var estimatedInterest: Double {
        max(0, estimatedTotalPayable - principal)
    }
}

struct PersistedState: Codable {
    var profile = UserProfile()
    var signedIn = false
    var appearance = Appearance.system
    var appFont = AppFont.modern
    var mainCurrency = "EUR"
    var millionCurrency = "EUR"
    var accounts: [Account] = []
    var transactions: [FinanceTransaction] = []
    var budgets: [Budget] = []
    var loans: [Loan] = []
}
