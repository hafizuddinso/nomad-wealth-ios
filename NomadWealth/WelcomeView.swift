import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var mode: AuthMode?
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var error = ""
    @State private var isSubmitting = false
    @State private var logoAnimating = false

    enum AuthMode: Identifiable {
        case login, signup
        var id: Int { self == .login ? 0 : 1 }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.07, blue: 0.14),
                    Color(red: 0.02, green: 0.14, blue: 0.18),
                    Color(red: 0.02, green: 0.07, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 26) {
                    publicHeader
                    heroSection
                    featureSection
                    previewSection
                    actionSection
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .sheet(item: $mode) { mode in
            authSheet(mode)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var publicHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.north.circle.fill")
                .font(.system(size: 42))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .teal)

            VStack(alignment: .leading, spacing: 2) {
                Text("Nomad Wealth")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                Text("Your money. Anywhere.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()

            Button("Log in") {
                AppHaptics.impact()
                mode = .login
            }
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.white.opacity(0.09), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.12)))
        }
    }

    private var heroSection: some View {
        VStack(spacing: 18) {
            Text("PERSONAL FINANCE ACROSS COUNTRIES")
                .font(.caption.bold())
                .tracking(1.25)
                .foregroundStyle(.teal)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.teal.opacity(0.12), in: Capsule())

            Image(systemName: "location.north.circle.fill")
                .font(.system(size: 78))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .teal)
                .scaleEffect(logoAnimating ? 1.05 : 0.96)
                .opacity(logoAnimating ? 1 : 0.84)
                .animation(
                    .easeInOut(duration: 1.15).repeatForever(autoreverses: true),
                    value: logoAnimating
                )
                .onAppear { logoAnimating = true }

            Text("Understand your money,\nwherever life takes you.")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .lineSpacing(2)

            Text(
                "Track accounts, income, expenses, budgets, loans and currencies from one simple native iPhone app."
            )
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundStyle(.white.opacity(0.72))
            .lineSpacing(5)
        }
        .padding(.top, 24)
    }

    private var featureSection: some View {
        VStack(spacing: 12) {
            FeatureCard(
                icon: "globe.europe.africa",
                title: "Multi-currency accounts",
                text: "Manage money held in different countries and currencies."
            )

            FeatureCard(
                icon: "arrow.left.arrow.right",
                title: "Simple money tracking",
                text: "Record Money In and Money Out with a clear recent history."
            )

            FeatureCard(
                icon: "building.columns",
                title: "Loans and installments",
                text: "Track principal, interest, monthly payments and remaining debt."
            )
        }
    }

    private var previewSection: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("FINANCIAL PREVIEW")
                        .font(.caption.bold())
                        .tracking(1)
                        .foregroundStyle(.teal)
                    Text("Everything important in one view")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                Spacer()
            }

            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Remaining balance")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                    Text("€2,070.00")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Income minus expenses")
                        .font(.caption)
                        .foregroundStyle(.teal)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.teal.opacity(0.42), .blue.opacity(0.26)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )

                HStack(spacing: 12) {
                    PreviewMetric(title: "Income", value: "+ €4,250", color: .green)
                    PreviewMetric(title: "Expenses", value: "− €2,180", color: .red)
                }

                VStack(spacing: 0) {
                    PreviewTransaction(
                        icon: "arrow.down.circle.fill",
                        title: "Salary",
                        subtitle: "Bank account",
                        amount: "+€3,200",
                        color: .green
                    )
                    Divider().overlay(.white.opacity(0.08))
                    PreviewTransaction(
                        icon: "arrow.up.circle.fill",
                        title: "Groceries",
                        subtitle: "Cash wallet",
                        amount: "−€48",
                        color: .red
                    )
                }
                .padding(.horizontal)
                .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 17))
            }
            .padding()
            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.09)))
        }
    }

    private var actionSection: some View {
        VStack(spacing: 12) {
            Button {
                AppHaptics.impact()
                mode = .signup
            } label: {
                Label("Create free account", systemImage: "person.badge.plus")
            }
            .buttonStyle(ScalePressButtonStyle(tint: .teal))

            Button {
                AppHaptics.impact()
                mode = .login
            } label: {
                Label("Log in", systemImage: "person.crop.circle")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .foregroundStyle(.white)
            .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(.white.opacity(0.14)))
        }
    }

    private var footer: some View {
        Text("Nomad Wealth · Developed by Hafizuddin")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.48))
            .padding(.top, 8)
    }

    @ViewBuilder
    private func authSheet(_ mode: AuthMode) -> some View {
        NavigationView {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "location.north.circle.fill")
                            .font(.title)
                            .foregroundStyle(.teal)

                        VStack(alignment: .leading) {
                            Text("Nomad Wealth").font(.headline)
                            Text(mode == .login ? "Welcome back" : "Create your account")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if mode == .signup {
                    TextField("Your name", text: $name)
                        .textContentType(.name)
                }

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)

                SecureField("Password", text: $password)
                    .textContentType(mode == .login ? .password : .newPassword)

                if mode == .signup {
                    SecureField("Confirm password", text: $confirmPassword)
                        .textContentType(.newPassword)
                }

                if !error.isEmpty {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                Button {
                    Task { await submit(mode) }
                } label: {
                    LoadingButtonLabel(
                        title: mode == .login ? "Log in" : "Create account",
                        loading: isSubmitting
                    )
                }
                .buttonStyle(ScalePressButtonStyle(tint: .teal))
                .disabled(isSubmitting)
                .listRowBackground(Color.clear)
            }
            .navigationTitle(mode == .login ? "Log in" : "Create account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { self.mode = nil }
                }
            }
        }
    }

    @MainActor
    private func submit(_ mode: AuthMode) async {
        error = ""

        guard email.contains("@"), password.count >= 6 else {
            error = "Enter a valid email and a password with at least 6 characters."
            AppHaptics.error()
            return
        }

        if mode == .signup {
            guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                error = "Enter your name."
                AppHaptics.error()
                return
            }

            guard password == confirmPassword else {
                error = "Passwords do not match."
                AppHaptics.error()
                return
            }
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            switch mode {
            case .signup:
                try await store.signUp(
                    name: name.trimmingCharacters(in: .whitespaces),
                    email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                    password: password
                )

                if store.signedIn {
                    AppHaptics.success()
                    self.mode = nil
                } else {
                    error = "Account created. Confirm your email before logging in."
                }

            case .login:
                try await store.logIn(
                    email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                    password: password
                )
                AppHaptics.success()
                self.mode = nil
            }
        } catch {
            AppHaptics.error()
            self.error = error.localizedDescription
        }
    }
}

private struct FeatureCard: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.teal)
                .frame(width: 48, height: 48)
                .background(.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.66))
            }

            Spacer()
        }
        .padding()
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.08)))
    }
}

private struct PreviewMetric: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.58))
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 15))
    }
}

private struct PreviewTransaction: View {
    let icon: String
    let title: String
    let subtitle: String
    let amount: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.56))
            }

            Spacer()

            Text(amount)
                .font(.subheadline.bold())
                .foregroundStyle(color)
        }
        .padding(.vertical, 12)
    }
}
