//
//  FatSecret.swift
//  Sodium Tracker
//
//  FatSecret Platform API integration: live food search and per-serving
//  sodium for the salt shelf. Uses OAuth 2 client credentials.
//
//  Setup: paste your credentials from platform.fatsecret.com below (or ship
//  them via the FATSECRET_CLIENT_ID / FATSECRET_CLIENT_SECRET scheme
//  environment variables while developing). With no credentials the app
//  quietly falls back to local-only search.
//

import Foundation

enum FatSecretConfig {
    /// Your OAuth 2 client credentials from platform.fatsecret.com.
    /// Resolution order:
    ///   1. FATSECRET_CLIENT_ID / FATSECRET_CLIENT_SECRET scheme env vars
    ///   2. FatSecretSecrets.plist bundled with the app (git-ignored — copy
    ///      FatSecretSecrets.sample.plist into "Sodium Tracker/Resources/",
    ///      rename it, and fill in the two values)
    static let clientID = resolve("FATSECRET_CLIENT_ID", plistKey: "ClientID")
    static let clientSecret = resolve("FATSECRET_CLIENT_SECRET", plistKey: "ClientSecret")

    static var isEnabled: Bool {
        !clientID.isEmpty && !clientSecret.isEmpty
    }

    private static func resolve(_ envKey: String, plistKey: String) -> String {
        if let env = ProcessInfo.processInfo.environment[envKey], !env.isEmpty {
            return env
        }
        if let url = Bundle.main.url(forResource: "FatSecretSecrets", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
           let value = plist[plistKey] as? String,
           !value.hasPrefix("YOUR-") {
            return value
        }
        return ""
    }

    /// Prefix for FatSecret-sourced food ids, so entries and favorites can
    /// tell them apart from the built-in catalog and the user's shelf.
    static let idPrefix = "fs-"
}

/// A search hit from FatSecret. Sodium is not in the search response —
/// it arrives with `details(id:)`.
struct RemoteFood: Identifiable, Equatable {
    let id: String          // FatSecret food_id
    let name: String
    let brand: String?
    let summary: String     // e.g. "Per 100g - Calories: 52kcal | …"

    /// Row subtitle: brand when present, else the portion the summary is for.
    var subtitle: String {
        if let brand, !brand.isEmpty { return brand }
        if let dash = summary.range(of: " - ") {
            return String(summary[..<dash.lowerBound])
        }
        return "FatSecret"
    }
}

/// Nutrition detail for one FatSecret food, reduced to what Pinch logs.
struct RemoteFoodDetail: Equatable {
    let name: String
    let serving: String     // e.g. "1 cup" / "100 g"
    let sodiumMg: Int
    let calories: Int?
}

enum FatSecretError: Error {
    case notConfigured
    case badResponse
    case noSodium
}

// MARK: - Service

actor FatSecretService {
    static let shared = FatSecretService()

    private var token: (value: String, expiry: Date)?
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        return URLSession(configuration: config)
    }()

    // MARK: Public API

    func search(_ query: String, maxResults: Int = 20) async throws -> [RemoteFood] {
        let data = try await call(params: [
            "method": "foods.search",
            "search_expression": query,
            "max_results": String(maxResults),
            "format": "json",
        ])
        return try FatSecretParser.searchResults(from: data)
    }

    func details(id: String) async throws -> RemoteFoodDetail {
        let data = try await call(params: [
            "method": "food.get.v2",
            "food_id": id,
            "format": "json",
        ])
        return try FatSecretParser.foodDetail(from: data)
    }

    // MARK: Transport

    private func call(params: [String: String]) async throws -> Data {
        guard FatSecretConfig.isEnabled else { throw FatSecretError.notConfigured }
        let bearer = try await validToken()

        var request = URLRequest(url: URL(string: "https://platform.fatsecret.com/rest/server.api")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formEncode(params).data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw FatSecretError.badResponse }
        if http.statusCode == 401 {
            // Token expired server-side: refresh once and retry.
            token = nil
            let fresh = try await validToken()
            request.setValue("Bearer \(fresh)", forHTTPHeaderField: "Authorization")
            let (data2, response2) = try await session.data(for: request)
            guard (response2 as? HTTPURLResponse)?.statusCode == 200 else {
                throw FatSecretError.badResponse
            }
            return data2
        }
        guard http.statusCode == 200 else { throw FatSecretError.badResponse }
        return data
    }

    private func validToken() async throws -> String {
        if let token, token.expiry > Date.now.addingTimeInterval(60) {
            return token.value
        }
        var request = URLRequest(url: URL(string: "https://oauth.fatsecret.com/connect/token")!)
        request.httpMethod = "POST"
        let basic = Data("\(FatSecretConfig.clientID):\(FatSecretConfig.clientSecret)".utf8)
            .base64EncodedString()
        request.setValue("Basic \(basic)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "grant_type=client_credentials&scope=basic".data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let value = json["access_token"] as? String else {
            throw FatSecretError.badResponse
        }
        let lifetime = (json["expires_in"] as? Double) ?? 3600
        token = (value, Date.now.addingTimeInterval(lifetime))
        return value
    }

    private func formEncode(_ params: [String: String]) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return params
            .map { key, value in
                let v = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
                return "\(key)=\(v)"
            }
            .joined(separator: "&")
    }
}

// MARK: - Response parsing (pure, testable)

enum FatSecretParser {
    /// FatSecret returns a lone object instead of an array when there is
    /// exactly one element — normalize both shapes.
    static func objectArray(_ value: Any?) -> [[String: Any]] {
        if let array = value as? [[String: Any]] { return array }
        if let single = value as? [String: Any] { return [single] }
        return []
    }

    static func searchResults(from data: Data) throws -> [RemoteFood] {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FatSecretError.badResponse
        }
        guard let foods = root["foods"] as? [String: Any] else {
            // {"error": …} or empty result envelope
            if root["error"] != nil { throw FatSecretError.badResponse }
            return []
        }
        return objectArray(foods["food"]).compactMap { entry in
            guard let id = string(entry["food_id"]),
                  let name = string(entry["food_name"]) else { return nil }
            return RemoteFood(
                id: id,
                name: name,
                brand: string(entry["brand_name"]),
                summary: string(entry["food_description"]) ?? ""
            )
        }
    }

    static func foodDetail(from data: Data) throws -> RemoteFoodDetail {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let food = root["food"] as? [String: Any] else {
            throw FatSecretError.badResponse
        }
        let name = string(food["food_name"]) ?? "Food"
        let servingsBox = food["servings"] as? [String: Any]
        let servings = objectArray(servingsBox?["serving"])

        // First serving carrying a sodium value (FatSecret's default first).
        for serving in servings {
            if let sodium = number(serving["sodium"]) {
                return RemoteFoodDetail(
                    name: name,
                    serving: string(serving["serving_description"]) ?? "1 serving",
                    sodiumMg: Int(sodium.rounded()),
                    calories: number(serving["calories"]).map { Int($0.rounded()) }
                )
            }
        }
        throw FatSecretError.noSodium
    }

    /// FatSecret encodes numbers as strings ("870"); accept both.
    static func number(_ value: Any?) -> Double? {
        if let d = value as? Double { return d }
        if let s = value as? String { return Double(s) }
        if let n = value as? NSNumber { return n.doubleValue }
        return nil
    }

    private static func string(_ value: Any?) -> String? {
        if let s = value as? String { return s.isEmpty ? nil : s }
        if let n = value as? NSNumber { return n.stringValue }
        return nil
    }
}
