//
//  SubscriptionStore.swift
//  Sodium Tracker
//
//  StoreKit 2 is the sole source of truth for Pinch Plus. Premium access is
//  granted only by a currently verified, non-revoked transaction.
//

import Foundation
import Observation
import StoreKit

enum PlusProduct {
    static let yearlyID = "com.kabi.sodium.tracker.SodiumTracker.plus.yearly"
    static let monthlyID = "com.kabi.sodium.tracker.SodiumTracker.plus.monthly"
    static let identifiers: Set<String> = [yearlyID, monthlyID]

    static func identifier(for plan: PlusPlan) -> String {
        switch plan {
        case .yearly: yearlyID
        case .monthly: monthlyID
        }
    }
}

enum PremiumFeature: CaseIterable {
    case monthTrends
    case historyCalendar
    case csvExport
    case remoteFoodLogging
    case barcodeScanner
    case unlimitedCustomFoods
    case widgets
}

enum PremiumAccessPolicy {
    /// A useful free taste without making the paid "unlimited shelf" hollow.
    static let freeCustomFoodLimit = 3

    static func allows(
        _ feature: PremiumFeature,
        isPremium: Bool,
        customFoodCount: Int = 0
    ) -> Bool {
        if isPremium { return true }
        switch feature {
        case .monthTrends, .historyCalendar, .csvExport, .remoteFoodLogging, .barcodeScanner, .widgets:
            return false
        case .unlimitedCustomFoods:
            return customFoodCount < freeCustomFoodLimit
        }
    }
}

@MainActor
@Observable
final class SubscriptionStore {
    private(set) var products: [Product] = []
    private(set) var isPremium = false
    private(set) var isLoading = false
    private(set) var isPurchasing = false
    var errorMessage: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?
    @ObservationIgnored private var hasPrepared = false

    var productsAvailable: Bool {
        !products.isEmpty
    }

    func prepare() async {
        guard !hasPrepared else {
            if products.isEmpty {
                isLoading = true
                await refreshProducts()
                isLoading = false
            }
            await refreshEntitlements()
            return
        }
        hasPrepared = true
        listenForTransactions()
        isLoading = true
        defer { isLoading = false }
        await refreshProducts()
        await refreshEntitlements()
    }

    func product(for plan: PlusPlan) -> Product? {
        let id = PlusProduct.identifier(for: plan)
        return products.first { $0.id == id }
    }

    func purchase(_ plan: PlusPlan) async -> Bool {
        guard let product = product(for: plan), !isPurchasing else {
            errorMessage = "Subscriptions are unavailable right now. Please try again shortly."
            return false
        }

        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            switch try await product.purchase() {
            case .success(let verification):
                let transaction = try verified(verification)
                await transaction.finish()
                await refreshEntitlements()
                return isPremium
            case .pending:
                errorMessage = "Your purchase is pending approval. Plus will unlock automatically once it completes."
            case .userCancelled:
                break
            @unknown default:
                errorMessage = "The purchase could not be completed. Please try again."
            }
        } catch {
            errorMessage = "The purchase could not be completed. Please try again."
        }
        return false
    }

    func restore() async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isPremium {
                errorMessage = "No active Pinch Plus purchase was found for this Apple Account."
            }
        } catch {
            errorMessage = "Purchases could not be restored. Please try again."
        }
    }

    func refreshEntitlements() async {
        var entitled = false
        let now = Date.now
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verified(result),
                  PlusProduct.identifiers.contains(transaction.productID),
                  transaction.revocationDate == nil,
                  transaction.expirationDate.map({ $0 > now }) ?? true else { continue }
            entitled = true
            break
        }
        isPremium = entitled
    }

    private func refreshProducts() async {
        do {
            let loaded = try await Product.products(for: PlusProduct.identifiers)
            products = loaded.sorted { lhs, rhs in
                if lhs.id == PlusProduct.yearlyID { return true }
                if rhs.id == PlusProduct.yearlyID { return false }
                return lhs.price < rhs.price
            }
            if !products.isEmpty { errorMessage = nil }
        } catch {
            products = []
            errorMessage = "Plans could not be loaded. Check your connection and try again."
        }
    }

    private func listenForTransactions() {
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = try? self.verified(result) {
                    await transaction.finish()
                }
                await self.refreshEntitlements()
            }
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified: throw VerificationError.failed
        }
    }

    private enum VerificationError: Error {
        case failed
    }
}
