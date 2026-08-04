import Foundation
import SwiftUI

enum Appearance: String, Codable, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self { case .system: return nil; case .light: return .light; case .dark: return .dark }
    }
}

enum AppFont: String, Codable, CaseIterable, Identifiable {
    case modern, system, rounded, serif, mono
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var design: Font.Design {
        switch self { case .modern, .system: return .default; case .rounded: return .rounded; case .serif: return .serif; case .mono: return .monospaced }
    }
}

enum AccountType: String, Codable, CaseIterable, Identifiable {
    case bank = "Bank", cash = "Cash", savings = "Savings", wallet = "Wallet", debt = "Debt"
    var id: String { rawValue }
}

enum TransactionKind: String, Codable, CaseIterable, Identifiable {
    case expense = "Expense", income = "Income"
    var id: String { rawValue }
}

enum BudgetPeriod: String, Codable, CaseIterable, Identifiable {
    case weekly = "Weekly", monthly = "Monthly", yearly = "Yearly"
    var id: String { rawValue }
}

struct UserProfile: Codable {
    var name = ""
    var email = ""
    var password = ""
    var photoData: Data?
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
    var period: BudgetPeriod = .monthly
    var accountID: UUID?
    var category: String
    var limit: Double
    var currency: String
    var startDate: Date = Date()
}

struct Investment: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var type: String
    var accountID: UUID?
    var currency: String
    var cost: Double
    var currentValue: Double
    var purchaseDate: Date
    var note: String
}

struct TravelPlan: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var origin: String? = nil
    var destination: String
    var accountID: UUID?
    var currency: String
    var budget: Double
    var startDate: Date
    var endDate: Date
    var accommodationPerDay: Double? = nil
    var foodPerDay: Double? = nil
    var localTransportPerDay: Double? = nil
    var activitiesPerDay: Double? = nil
    var oneTimeTransport: Double? = nil
    var notes: String? = nil

    var dayCount: Int {
        max(1, (Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0) + 1)
    }

    var automaticDailyBudget: Double { budget / Double(dayCount) }

    var plannedDailyCost: Double {
        (accommodationPerDay ?? 0) + (foodPerDay ?? 0) +
        (localTransportPerDay ?? 0) + (activitiesPerDay ?? 0)
    }

    var plannedTotal: Double {
        plannedDailyCost * Double(dayCount) + (oneTimeTransport ?? 0)
    }
}

struct AccountAdjustmentRecord: Identifiable, Codable, Hashable {
    var id = UUID()
    var accountID: UUID
    var type: String
    var amount: Double
    var previousBalance: Double
    var newBalance: Double
    var date: Date
    var note: String
}

struct LoanPayment: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date
    var amount: Double
    var principal: Double
    var interest: Double
    var extraPayment: Double = 0
}

struct Loan: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var lender: String
    var accountID: UUID? = nil
    var currency: String
    var assetPrice: Double = 0
    var initialDeposit: Double = 0
    var principal: Double
    var annualRate: Double
    var termMonths: Int
    var installment: Double
    var startDate: Date
    var nextPaymentDate: Date
    var payments: [LoanPayment] = []
    var totalPaid: Double { payments.reduce(0) { $0 + $1.amount + $1.extraPayment } }
    var principalPaid: Double { payments.reduce(0) { $0 + $1.principal + $1.extraPayment } }
    var interestPaid: Double { payments.reduce(0) { $0 + $1.interest } }
    var remainingPrincipal: Double { max(0, principal - principalPaid) }
    var estimatedTotalPayable: Double { installment * Double(max(termMonths, 1)) }
    var estimatedInterest: Double { max(0, estimatedTotalPayable - principal) }
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
    var investments: [Investment] = []
    var travelPlans: [TravelPlan] = []
    var loans: [Loan] = []
    var accountAdjustments: [AccountAdjustmentRecord]? = nil
}
