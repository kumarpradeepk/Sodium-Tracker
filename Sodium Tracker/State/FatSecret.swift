//
//  FatSecret.swift
//  Sodium Tracker
//
//  FatSecret Platform API integration: live food search and per-serving
//  sodium for the salt shelf. Requests go only to an app-owned HTTPS proxy.
//  The proxy, not this app, owns the FatSecret OAuth 2 credentials and token.
//  Search failures are surfaced explicitly; saved foods remain available.
//

import Foundation
import os

/// Shared logger for the FatSecret integration. Filter the Xcode console
/// with "FatSecret" to follow the whole chain.
let fatSecretLog = Logger(subsystem: "com.kabi.sodium.tracker", category: "FatSecret")

enum FatSecretConfig {
    /// The public base URL of the narrowly scoped, app-owned API proxy.
    /// This is not a credential and may be provided by a development scheme
    /// environment variable or the `FatSecretProxyURL` app Info setting.
    static let proxyBaseURL = resolveProxyBaseURL()
    static let proxyAPIKey = resolveProxyAPIKey()

    static var isEnabled: Bool {
        URL(string: proxyBaseURL)?.scheme?.lowercased() == "https"
            && !proxyAPIKey.isEmpty
    }

    /// Logs the public proxy configuration exactly once per launch. Never log
    /// OAuth credentials, access tokens, or complete food-search terms.
    static let logConfigurationOnce: Void = {
        if isEnabled {
            let host = URL(string: proxyBaseURL)?.host ?? "configured host"
            fatSecretLog.info("✅ secure proxy configured (\(host, privacy: .public)) — remote search ENABLED")
        } else {
            fatSecretLog.warning("⚠️ FatSecret proxy URL or app API key missing — remote search DISABLED, local catalog only")
        }
    }()

    private static func resolveProxyBaseURL() -> String {
        let value = ProcessInfo.processInfo.environment["FATSECRET_PROXY_URL"]
            ?? Bundle.main.object(forInfoDictionaryKey: "FatSecretProxyURL") as? String
            ?? ""
        return value.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
    }

    private static func resolveProxyAPIKey() -> String {
        var candidates = [ProcessInfo.processInfo.environment["PINCH_PROXY_API_KEY"],
                          Bundle.main.object(forInfoDictionaryKey: "PinchProxyAPIKey") as? String]
        if let url = Bundle.main.url(forResource: "PinchProxyConfig", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let config = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] {
            candidates.append(config["apiKey"])
        }
        return candidates.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty && !$0.hasPrefix("$(") } ?? ""
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
    var displayName: String { name }

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

@MainActor
final class FatSecretService {
    static let shared = FatSecretService()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        return URLSession(configuration: config)
    }()

    // MARK: Public API

    func search(_ query: String, maxResults: Int = 20) async throws -> [RemoteFood] {
        _ = FatSecretConfig.logConfigurationOnce
        let data = try await get(path: "search", queryItems: [
            URLQueryItem(name: "q", value: String(query.prefix(120))),
            URLQueryItem(name: "limit", value: String(min(max(maxResults, 1), 20))),
        ])
        let hits = try FatSecretProxyParser.searchResults(from: data)
        fatSecretLog.info("🔎 remote search → \(hits.count) result(s)")
        return hits
    }

    func details(id: String) async throws -> RemoteFoodDetail {
        guard !id.isEmpty, id.count <= 20, id.utf8.allSatisfy({ (48...57).contains($0) }) else { throw FatSecretError.badResponse }
        let data = try await get(path: "food/\(id)")
        do {
            let detail = try FatSecretProxyParser.foodDetail(from: data)
            fatSecretLog.info("🧂 \(detail.name, privacy: .public): \(detail.sodiumMg) mg per \(detail.serving, privacy: .public)")
            return detail
        } catch {
            fatSecretLog.error("✗ food \(id, privacy: .public) has no usable sodium data: \(Self.snippet(data), privacy: .public)")
            throw error
        }
    }

    /// First 300 chars of a response body, for error logs.
    private static func snippet(_ data: Data) -> String {
        String(decoding: data.prefix(300), as: UTF8.self)
    }

    // MARK: Transport

    private func get(path: String, queryItems: [URLQueryItem] = []) async throws -> Data {
        guard FatSecretConfig.isEnabled else { throw FatSecretError.notConfigured }
        guard var components = URLComponents(string: FatSecretConfig.proxyBaseURL) else {
            throw FatSecretError.notConfigured
        }
        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = "/" + [basePath, path]
            .filter { !$0.isEmpty }
            .joined(separator: "/")
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else { throw FatSecretError.badResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        request.setValue("ios", forHTTPHeaderField: "X-Pinch-Platform")
        request.setValue("Bearer \(FatSecretConfig.proxyAPIKey)", forHTTPHeaderField: "Authorization")
        fatSecretLog.debug("→ proxy \(path, privacy: .public)")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            fatSecretLog.error("✗ proxy \(path, privacy: .public): no HTTP response")
            throw FatSecretError.badResponse
        }
        fatSecretLog.debug("← proxy \(path, privacy: .public) HTTP \(http.statusCode) (\(data.count) bytes)")
        if http.statusCode == 422 { throw FatSecretError.noSodium }
        guard http.statusCode == 200 else {
            fatSecretLog.error("✗ proxy \(path, privacy: .public) HTTP \(http.statusCode): \(Self.snippet(data), privacy: .public)")
            throw FatSecretError.badResponse
        }
        return data
    }
}

// MARK: - Proxy response parsing

/// The proxy returns an intentionally small, stable JSON contract. FatSecret's
/// upstream response is never passed through wholesale to a mobile device.
enum FatSecretProxyParser {
    static func searchResults(from data: Data) throws -> [RemoteFood] {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let foods = root["foods"] as? [[String: Any]] else {
            throw FatSecretError.badResponse
        }
        return foods.compactMap { entry in
            guard let id = FatSecretParser.string(entry["id"]),
                  let name = FatSecretParser.string(entry["name"]) else { return nil }
            return RemoteFood(
                id: id,
                name: name,
                brand: FatSecretParser.string(entry["brand"]),
                summary: FatSecretParser.string(entry["summary"]) ?? ""
            )
        }
    }

    static func foodDetail(from data: Data) throws -> RemoteFoodDetail {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = FatSecretParser.string(root["name"]),
              let sodium = FatSecretParser.nonnegativeInt(root["sodiumMg"]) else {
            throw FatSecretError.badResponse
        }
        return RemoteFoodDetail(
            name: name,
            serving: FatSecretParser.string(root["serving"]) ?? "1 serving",
            sodiumMg: sodium,
            calories: FatSecretParser.nonnegativeInt(root["calories"])
        )
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
            if let sodium = nonnegativeInt(serving["sodium"]) {
                return RemoteFoodDetail(
                    name: name,
                    serving: string(serving["serving_description"]) ?? "1 serving",
                    sodiumMg: sodium,
                    calories: nonnegativeInt(serving["calories"])
                )
            }
        }
        throw FatSecretError.noSodium
    }

    /// FatSecret encodes numbers as strings ("870"); accept both.
    static func nonnegativeInt(_ value: Any?) -> Int? {
        guard let number = number(value), number.isFinite, number >= 0,
              number.rounded() < Double(Int.max) else { return nil }
        return Int(number.rounded())
    }

    static func number(_ value: Any?) -> Double? {
        if let d = value as? Double { return d }
        if let s = value as? String { return Double(s) }
        if let n = value as? NSNumber { return n.doubleValue }
        return nil
    }

    static func string(_ value: Any?) -> String? {
        if let s = value as? String { return s.isEmpty ? nil : s }
        if let n = value as? NSNumber { return n.stringValue }
        return nil
    }
}
