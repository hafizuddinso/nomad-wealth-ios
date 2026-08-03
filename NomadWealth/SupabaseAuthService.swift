import Foundation
import Security

struct SupabaseUser: Codable {
    let id: String
    let email: String?
    let userMetadata: [String: JSONValue]?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case userMetadata = "user_metadata"
    }

    var displayName: String {
        if case let .string(name)? = userMetadata?["full_name"], !name.isEmpty {
            return name
        }
        if case let .string(name)? = userMetadata?["name"], !name.isEmpty {
            return name
        }
        return email?.split(separator: "@").first.map(String.init) ?? "User"
    }
}

enum JSONValue: Codable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported JSON value"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

struct SupabaseSessionResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
    let user: SupabaseUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case user
    }
}

struct SupabaseSignupResponse: Codable {
    let accessToken: String?
    let refreshToken: String?
    let user: SupabaseUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct SupabaseErrorResponse: Codable {
    let message: String?
    let errorDescription: String?
    let msg: String?

    enum CodingKeys: String, CodingKey {
        case message
        case errorDescription = "error_description"
        case msg
    }

    var bestMessage: String {
        message ?? errorDescription ?? msg ?? "Authentication failed."
    }
}

enum SupabaseAuthError: LocalizedError {
    case invalidResponse
    case server(String)
    case emailConfirmationRequired

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The authentication server returned an invalid response."
        case .server(let message):
            return message
        case .emailConfirmationRequired:
            return "Account created. Check your email and confirm the account before logging in."
        }
    }
}

final class SupabaseAuthService {
    static let shared = SupabaseAuthService()

    private let projectURL = URL(string: "https://kddlsbtfxgtmbpthtcjt.supabase.co")!
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtkZGxzYnRmeGd0bWJwdGh0Y2p0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU2NzI1MzEsImV4cCI6MjEwMTI0ODUzMX0.knFs8gbzsVIMDe2kqj55Yxwywob1q0U_9iW4OiPnh18"

    private init() {}

    func signIn(email: String, password: String) async throws -> SupabaseSessionResponse {
        let endpoint = projectURL
            .appendingPathComponent("auth/v1/token")
            .appending(queryItems: [URLQueryItem(name: "grant_type", value: "password")])

        let body: [String: Any] = [
            "email": email,
            "password": password
        ]

        let data = try await performRequest(
            endpoint: endpoint,
            method: "POST",
            body: body
        )

        let response = try JSONDecoder().decode(SupabaseSessionResponse.self, from: data)
        KeychainStore.save(response.accessToken, for: "nomad_access_token")

        if let refreshToken = response.refreshToken {
            KeychainStore.save(refreshToken, for: "nomad_refresh_token")
        }

        return response
    }

    func signUp(name: String, email: String, password: String) async throws -> SupabaseUser? {
        let endpoint = projectURL.appendingPathComponent("auth/v1/signup")

        let body: [String: Any] = [
            "email": email,
            "password": password,
            "data": [
                "full_name": name,
                "country": "AL",
                "main_currency": "EUR",
                "user_type": "Other",
                "language": "en",
                "theme": "system",
                "onboarding_complete": TrueValue.value
            ]
        ]

        let data = try await performRequest(
            endpoint: endpoint,
            method: "POST",
            body: body
        )

        let response = try JSONDecoder().decode(SupabaseSignupResponse.self, from: data)

        if let token = response.accessToken {
            KeychainStore.save(token, for: "nomad_access_token")
            if let refreshToken = response.refreshToken {
                KeychainStore.save(refreshToken, for: "nomad_refresh_token")
            }
            return response.user
        }

        throw SupabaseAuthError.emailConfirmationRequired
    }

    func signOut() {
        KeychainStore.delete("nomad_access_token")
        KeychainStore.delete("nomad_refresh_token")
    }

    private func performRequest(
        endpoint: URL,
        method: String,
        body: [String: Any]
    ) async throws -> Data {
        var request = URLRequest(url: endpoint)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw SupabaseAuthError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let decoded = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: data)
            throw SupabaseAuthError.server(
                friendlyMessage(decoded?.bestMessage ?? "Authentication failed.")
            )
        }

        return data
    }

    private func friendlyMessage(_ message: String) -> String {
        let lower = message.lowercased()

        if lower.contains("invalid login credentials") {
            return "The email or password is incorrect."
        }
        if lower.contains("email not confirmed") {
            return "Confirm your email before logging in."
        }
        if lower.contains("user already registered") {
            return "An account already exists for this email. Log in instead."
        }
        if lower.contains("password") && lower.contains("characters") {
            return "Use a password with at least 6 characters."
        }
        if lower.contains("rate limit") {
            return "Too many attempts. Wait a little and try again."
        }

        return message
    }
}

private enum TrueValue {
    static let value = true
}

enum KeychainStore {
    static func save(_ value: String, for key: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func value(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}

private extension URL {
    func appending(queryItems: [URLQueryItem]) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        return components.url!
    }
}
