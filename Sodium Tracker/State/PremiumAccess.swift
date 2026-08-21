//
//  PremiumAccess.swift
//  Sodium Tracker
//
//  Shared premium policy and verified StoreKit 2 entitlement source.
//

import Foundation
import Observation
import StoreKit

enum PremiumFeature {
    case monthTrends
    case historyCalendar
    case csvExport
    case remoteFoodLogging
    case barcodeScanner
    case unlimitedCustomFoods
    case widgets
}

enum PremiumAccessPolicy {
    static let freeCustomFoodLimit = 3

    static func allows(_ feature: PremiumFeature, isPremium: Bool, customFoodCount: Int = 0) -> Bool {
        if isPremium { return true }
        switch feature {
        case .monthTrends, .historyCalendar, .csvExport, .remoteFoodLogging,
             .barcodeScanner, .widgets:
            return false
        case .unlimitedCustomFoods:
            return customFoodCount < freeCustomFoodLimit
        }
    }
}

@MainActor
@Observable
final class PurchaseManager {
    static let yearlyProductID = "pinch_plus_yearly"
    static let monthlyProductID = "pinch_plus_monthly"

    private(set) var products: [Product] = []
    private(set) var isLoading = false
    private(set) var isPurchasing = false
    private(set) var errorMessage: String?

    private var updateTask: Task<Void, Never>?

    init() {
        updateTask = observeTransactions()
    }

    func start() async {
        await refreshEntitlements()
        await loadProducts()
    }

    func product(for plan: PlusPlan) -> Product? {
        let id = plan == .yearly ? Self.yearlyProductID : Self.monthlyProductID
        return products.first { $0.id == id }
    }

    func purchase(_ plan: PlusPlan) async -> Bool {
        guard let product = product(for: plan) else {
            errorMessage = "Subscriptions are unavailable right now. Please try again shortly."
            await loadProducts()
            return false
        }
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            switch try await product.purchase() {
            case .success(let verification):
                let transaction = try Self.verified(verification)
                await transaction.finish()
                await refreshEntitlements()
                return UserDefaults.standard.bool(forKey: PinchDefaults.plus)
            case .pending, .userCancelled:
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = "The purchase could not be completed. Please try again."
            return false
        }
    }

    func restore() async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !UserDefaults.standard.bool(forKey: PinchDefaults.plus) {
                errorMessage = "No active Pinch Plus purchase was found for this Apple Account."
            }
        } catch {
            errorMessage = "Purchases could not be restored. Please try again."
        }
    }

    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? Self.verified(result) else { continue }
            guard transaction.revocationDate == nil,
                  transaction.expirationDate.map({ $0 > .now }) ?? true else { continue }
            if transaction.productID == Self.yearlyProductID || transaction.productID == Self.monthlyProductID {
                active = true
            }
        }
        UserDefaults.standard.set(active, forKey: PinchDefaults.plus)
    }

    private func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: [Self.yearlyProductID, Self.monthlyProductID])
            if products.isEmpty {
                errorMessage = "Plans could not be loaded. Check your connection and try again."
            }
        } catch {
            products = []
            errorMessage = "Plans could not be loaded. Check your connection and try again."
        }
    }

    private func observeTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let transaction = try? Self.verified(result) else { continue }
                await transaction.finish()
                await self?.refreshEntitlements()
            }
        }
    }

    nonisolated private static func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified: throw StoreError.failedVerification
        }
    }

    private enum StoreError: Error { case failedVerification }
}
