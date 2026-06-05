import Foundation
import SwiftData

protocol FoodRecognizing {
    func loadUsage(from context: ModelContext) throws -> FoodAIUsage
    func recognize(imageData: Data, mimeType: String, context: ModelContext) async throws -> FoodRecognitionResult
}

enum FoodRecognitionError: LocalizedError {
    case dailyLimitReached(FoodAIUsage)
    case emptyImage
    case invalidPayload
    case networkError(String)
    case serverError(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .dailyLimitReached(let usage):
            return L10n.string("food.error.dailyLimit", "\(usage.usedCount)", "\(usage.dailyLimit)")
        case .emptyImage:
            return L10n.string("food.error.emptyImage")
        case .invalidPayload:
            return L10n.string("food.error.invalidResult")
        case .networkError(let message):
            return L10n.string("food.error.network", message)
        case .serverError(let statusCode, let message):
            let base = L10n.string("food.error.server", "\(statusCode)")
            if let message {
                return "\(base): \(message)"
            }
            return base
        }
    }
}

struct FoodRecognitionService: FoodRecognizing {
    private enum Constants {
        static let defaultBaseURL = "http://localhost:8787"
    }

    private let foodEndpoint: URL
    private let session: URLSession

    init(
        baseURL: URL = URL(
            string: ProcessInfo.processInfo.environment["FOOD_RECOGNITION_API_BASE_URL"]
                ?? FoodRecognitionService.Constants.defaultBaseURL
        ) ?? URL(string: Constants.defaultBaseURL)!,
        session: URLSession = .shared
    ) {
        foodEndpoint = baseURL.appendingPathComponent("v1").appendingPathComponent("food").appendingPathComponent("recognize")
        self.session = session
    }

    func loadUsage(from context: ModelContext) throws -> FoodAIUsage {
        let model = try usageModel(for: Date(), in: context)
        return FoodAIUsage(usedCount: model.usedCount, dailyLimit: model.dailyLimit)
    }

    func recognize(imageData: Data, mimeType: String, context: ModelContext) async throws -> FoodRecognitionResult {
        let currentUsage = try loadUsage(from: context)
        guard currentUsage.canUseForRecognition else {
            throw FoodRecognitionError.dailyLimitReached(currentUsage)
        }
        guard !imageData.isEmpty else { throw FoodRecognitionError.emptyImage }

        var request = URLRequest(url: foodEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = FoodRecognitionRequest(
            imageBase64: imageData.base64EncodedString(),
            mimeType: mimeType
        )

        request.httpBody = try JSONEncoder().encode(payload)

        do {
            let (data, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw FoodRecognitionError.networkError(L10n.string("food.error.networkResponseMissing"))
            }

            guard 200..<300 ~= response.statusCode else {
                let message = String(data: data, encoding: .utf8)
                throw FoodRecognitionError.serverError(statusCode: response.statusCode, message: message)
            }

            let decoded = try JSONDecoder().decode(
                FoodRecognitionResponse.self,
                from: data
            )

            let result = FoodRecognitionResult(
                foodName: decoded.resolvedName.trimmingCharacters(in: .whitespacesAndNewlines),
                estimatedCalories: decoded.resolvedCalories
            )

            guard !result.foodName.isEmpty else { throw FoodRecognitionError.invalidPayload }
            try incrementUsage(for: Date(), in: context)

            return result
        } catch let error as FoodRecognitionError {
            throw error
        } catch {
            throw FoodRecognitionError.networkError(error.localizedDescription)
        }
    }

    func incrementUsage(for date: Date, in context: ModelContext) throws {
        let model = try usageModel(for: date, in: context)
        model.usedCount += 1
        model.updatedAt = Date()
        try context.save()
    }

    private func usageModel(for date: Date, in context: ModelContext) throws -> AIUsageModel {
        let startOfDay = AIUsageModel.startOfDay(for: date)
        var descriptor = FetchDescriptor<AIUsageModel>(predicate: #Predicate { $0.date == startOfDay })
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            return existing
        }

        let model = AIUsageModel(date: startOfDay, usedCount: 0, dailyLimit: FoodAIUsage.defaultDailyLimit)
        context.insert(model)
        try context.save()
        return model
    }
}

struct FoodRecognitionRequest: Codable {
    let imageBase64: String
    let mimeType: String
}

private struct FoodRecognitionResponse: Decodable {
    let foodName: String?
    let estimatedCalories: Int?
    let alternativeName: String?
    let alternativeCalories: Int?

    var resolvedName: String {
        foodName ?? alternativeName ?? L10n.string("food.result.unavailable")
    }

    var resolvedCalories: Int {
        max(0, estimatedCalories ?? alternativeCalories ?? 0)
    }
}

private extension FoodRecognitionResponse {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)

        let foodNameKey = DynamicCodingKeys.mandatory("foodName")
        if let name = try container.decodeIfPresent(String.self, forKey: foodNameKey) {
            foodName = name
        } else if let name = try container.decodeIfPresent(String.self, forKey: DynamicCodingKeys.mandatory("name")) {
            foodName = name
        } else {
            foodName = nil
        }

        if let calories = try container.decodeIfPresent(Int.self, forKey: DynamicCodingKeys.mandatory("estimatedCalories")) {
            estimatedCalories = calories
        } else if let calories = try container.decodeIfPresent(Int.self, forKey: DynamicCodingKeys.mandatory("calories")) {
            estimatedCalories = calories
        } else {
            estimatedCalories = nil
        }
        if let name = try container.decodeIfPresent(String.self, forKey: DynamicCodingKeys.mandatory("food")) {
            alternativeName = name
        } else {
            alternativeName = nil
        }
        if let calories = try container.decodeIfPresent(Int.self, forKey: DynamicCodingKeys.mandatory("kcal")) {
            alternativeCalories = calories
        } else if let caloriesString = try container.decodeIfPresent(String.self, forKey: DynamicCodingKeys.mandatory("kcal")) {
            alternativeCalories = Int(caloriesString)
        } else {
            alternativeCalories = nil
        }
    }
}

private struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

private extension DynamicCodingKeys {
    static func mandatory(_ stringValue: String) -> DynamicCodingKeys {
        DynamicCodingKeys(stringValue: stringValue)!
    }
}

// Lightweight local test helper for unit tests or previews.
struct MockFoodRecognitionService: FoodRecognizing {
    var result: FoodRecognitionResult
    var dailyUsage: FoodAIUsage

    init(result: FoodRecognitionResult = .init(foodName: "Mock dish", estimatedCalories: 150), dailyUsage: FoodAIUsage = .zero) {
        self.result = result
        self.dailyUsage = dailyUsage
    }

    func loadUsage(from context: ModelContext) throws -> FoodAIUsage {
        dailyUsage
    }

    func recognize(imageData _: Data, mimeType _: String, context: ModelContext) async throws -> FoodRecognitionResult {
        guard dailyUsage.canUseForRecognition else {
            throw FoodRecognitionError.dailyLimitReached(dailyUsage)
        }
        return result
    }
}
