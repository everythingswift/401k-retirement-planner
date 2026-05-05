import Foundation

/// A user-saved snapshot of the 10 RetirementStore inputs, persisted on-device.
///
/// Snapshots capture inputs only, never projection results — the projection is
/// deterministic, so reload reproduces identical numbers without freezing the
/// model behind us.
struct SavedPlan: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    let createdAt: Date

    var retireAge: Int
    var totalPortfolio: Double
    var annualSpend: Double
    var rentalIncome: Double
    var socialSecurityAge: Int
    var socialSecurityAmt: Double
    var bondAllocation: Double
    var bondReturn: Double
    var equityReturn: Double
    var inflationRate: Double

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        retireAge: Int,
        totalPortfolio: Double,
        annualSpend: Double,
        rentalIncome: Double,
        socialSecurityAge: Int,
        socialSecurityAmt: Double,
        bondAllocation: Double,
        bondReturn: Double,
        equityReturn: Double,
        inflationRate: Double
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.retireAge = retireAge
        self.totalPortfolio = totalPortfolio
        self.annualSpend = annualSpend
        self.rentalIncome = rentalIncome
        self.socialSecurityAge = socialSecurityAge
        self.socialSecurityAmt = socialSecurityAmt
        self.bondAllocation = bondAllocation
        self.bondReturn = bondReturn
        self.equityReturn = equityReturn
        self.inflationRate = inflationRate
    }

    /// Captures the current state of `store` into a new SavedPlan with a fresh id and timestamp.
    init(capturing store: RetirementStore, name: String, createdAt: Date = Date()) {
        self.init(
            id: UUID(),
            name: name,
            createdAt: createdAt,
            retireAge: store.retireAge,
            totalPortfolio: store.totalPortfolio,
            annualSpend: store.annualSpend,
            rentalIncome: store.rentalIncome,
            socialSecurityAge: store.socialSecurityAge,
            socialSecurityAmt: store.socialSecurityAmt,
            bondAllocation: store.bondAllocation,
            bondReturn: store.bondReturn,
            equityReturn: store.equityReturn,
            inflationRate: store.inflationRate
        )
    }

    /// One-line description of the plan's key inputs, used in the list row.
    var summary: String {
        "Retire \(retireAge) · \(fmtCurrency(totalPortfolio)) · \(Int(bondAllocation))% bonds"
    }
}
