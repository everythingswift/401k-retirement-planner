import Foundation
import XCTest
@testable import RetirementPlanner

// MARK: - Inflation fixture types

struct InflationFixtures: Decodable {
    let factorBasic: FactorCase
    let toNominalBasic: ToNominalCase
    let toRealBasic: ToRealCase
    let realReturnBasic: RealReturnCase
    let adjustedContributionBasic: AdjustedContributionCase

    struct FactorCase: Decodable {
        let inflationRate, years, expected: Double
    }
    struct ToNominalCase: Decodable {
        let realValue, inflationRate, years, expected: Double
    }
    struct ToRealCase: Decodable {
        let nominalValue, inflationRate, years, expectedReal: Double
    }
    struct RealReturnCase: Decodable {
        let nominalRate, inflationRate, expected: Double
    }
    struct AdjustedContributionCase: Decodable {
        let baseContribution, inflationRate, yearsElapsed, expected: Double
    }
}

// MARK: - FourPercent fixture types

struct FourPercentFixtures: Decodable {
    let safeWithdrawalDefault: SafeWithdrawalCase
    let safeWithdrawalCustom: SafeWithdrawalCase
    let fireNumberDefault: FireNumberCase
    let fireProgressPartial: FireProgressCase
    let fireProgressClamped: FireProgressCase
    let yearsOfExpensesNormal: YearsOfExpensesCase
    let yearsOfExpensesZero: YearsOfExpensesInfinityCase

    struct SafeWithdrawalCase: Decodable {
        let portfolioValue: Double
        let withdrawalRate: Double?
        let expectedAnnual, expectedMonthly: Double
    }
    struct FireNumberCase: Decodable {
        let annualExpenses, expectedPortfolio: Double
    }
    struct FireProgressCase: Decodable {
        let currentPortfolio, targetPortfolio, expected: Double
    }
    struct YearsOfExpensesCase: Decodable {
        let portfolioValue, annualExpenses, expected: Double
    }
    /// Handles the "Infinity" string sentinel for JSON cases that produce Double.infinity.
    struct YearsOfExpensesInfinityCase: Decodable {
        let portfolioValue, annualExpenses: Double
        let expected: String
        var expectedDouble: Double { expected == "Infinity" ? .infinity : Double(expected) ?? .nan }
    }
}

// MARK: - Projection fixture types

struct ProjectionFixtures: Decodable {
    let input: InputCase
    let snapshots: [SnapshotCase]
    let totalContributions: Double
    let totalGains: Double

    struct InputCase: Decodable {
        let currentPortfolio, annualContribution, annualReturnRate, inflationRate: Double
        let currentAge, retirementAge: Int
        let inflationAdjustContributions: Bool
        let startYear: Int

        var asProjectionInput: ProjectionInput {
            ProjectionInput(
                currentPortfolio: currentPortfolio,
                annualContribution: annualContribution,
                annualReturnRate: annualReturnRate,
                inflationRate: inflationRate,
                currentAge: currentAge,
                retirementAge: retirementAge,
                inflationAdjustContributions: inflationAdjustContributions
            )
        }
    }

    struct SnapshotCase: Decodable {
        let year, age: Int
        let portfolioNominal, portfolioReal, annualContribution, investmentGains: Double
    }
}

// MARK: - Root fixture

struct CoreFixtures: Decodable {
    let inflation: InflationFixtures
    let fourPercent: FourPercentFixtures
    let projectionAdjusted: ProjectionFixtures
    let projectionFlat: ProjectionFixtures
}

// MARK: - Loader

final class FixtureLoader {
    static func load() throws -> CoreFixtures {
        let bundle = Bundle(for: FixtureLoader.self)
        guard let url = bundle.url(forResource: "core-fixtures", withExtension: "json") else {
            XCTFail("core-fixtures.json not found in test bundle — check Copy Bundle Resources")
            struct MissingFixture: Error {}
            throw MissingFixture()
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(CoreFixtures.self, from: data)
    }
}
