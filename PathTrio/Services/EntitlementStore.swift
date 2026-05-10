import Foundation
import Observation
import StoreKit

enum ProProduct: String, CaseIterable, Identifiable {
    case lifetime = "pathtrio.pro.lifetime"

    var id: String { rawValue }
}

enum ProPurchaseState: Equatable {
    case idle
    case loading
    case purchasing
    case purchased
    case failed
}

@Observable
final class EntitlementStore {
    var isProUnlocked: Bool
    var availableProducts: [Product] = []
    var purchaseState: ProPurchaseState = .idle
    var lastErrorMessage: String?

    init(isProUnlocked: Bool = false) {
        self.isProUnlocked = isProUnlocked
    }

    func canUse(_ feature: ProFeature) -> Bool {
        isProUnlocked
    }

    @MainActor
    func loadProducts() async {
        purchaseState = .loading
        do {
            availableProducts = try await Product.products(for: ProProduct.allCases.map(\.rawValue))
                .sorted { $0.price < $1.price }
            purchaseState = .idle
        } catch {
            lastErrorMessage = error.localizedDescription
            purchaseState = .failed
        }
    }

    @MainActor
    func refreshPurchasedEntitlements() async {
        var hasActiveProEntitlement = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if ProProduct(rawValue: transaction.productID) != nil {
                hasActiveProEntitlement = true
                break
            }
        }

        isProUnlocked = hasActiveProEntitlement
    }

    @MainActor
    func purchase(_ product: Product) async {
        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    purchaseState = .failed
                    return
                }
                if ProProduct(rawValue: transaction.productID) != nil {
                    isProUnlocked = true
                }
                await transaction.finish()
                purchaseState = .purchased
            case .pending, .userCancelled:
                purchaseState = .idle
            @unknown default:
                purchaseState = .failed
            }
        } catch {
            lastErrorMessage = error.localizedDescription
            purchaseState = .failed
        }
    }
}
