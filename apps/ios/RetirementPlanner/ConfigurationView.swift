import SwiftUI

struct ConfigurationView: View {
    @Bindable var store: RetirementStore
    @State private var showingSavedPlans = false

    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                // MARK: - Summary banner
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            summaryChip(label: "Cash Reserve", value: fmtCurrency(store.initialCash))
                            summaryChip(label: "Investment Pot", value: fmtCurrency(store.investable))
                        }
                        HStack {
                            summaryChip(label: "Yr 1 Growth", value: fmtCurrency(store.yr1Return))
                            summaryChip(label: "To Age 100", value: fmtCurrency(store.finalPortfolio))
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                // MARK: - Section 1
                Section(header: sectionHeader("1. Your Retirement")) {
                    fieldRow(
                        icon: "birthday.cake",
                        title: "Retirement Age",
                        value: "\(store.retireAge) yrs",
                        destination: EditValueView(
                            title: "Retirement Age",
                            subtitle: "Age at which you stop working",
                            note: "Projection runs to age 100 (\(100 - store.retireAge) years)",
                            min: 45, max: 80, step: 1,
                            format: .age,
                            value: Binding(
                                get: { Double(store.retireAge) },
                                set: { store.retireAge = Int($0) }
                            )
                        )
                    )

                    fieldRow(
                        icon: "banknote",
                        title: "Portfolio at Retirement",
                        value: fmtCurrency(store.totalPortfolio),
                        destination: EditValueView(
                            title: "Portfolio at Retirement",
                            subtitle: "Total 401k, IRA, savings + investments",
                            min: 50_000, max: 10_000_000, step: 10_000,
                            format: .currency,
                            value: $store.totalPortfolio
                        )
                    )
                }

                // MARK: - Section 2
                Section(header: sectionHeader("2. Living Expenses")) {
                    fieldRow(
                        icon: "cart",
                        title: "Annual Spending",
                        value: fmtCurrency(store.annualSpend),
                        destination: EditValueView(
                            title: "Annual Spending",
                            subtitle: "Comfortable lifestyle cost per year (today's dollars)",
                            note: "All spending grows with inflation over time",
                            min: 20_000, max: 400_000, step: 1_000,
                            format: .currency,
                            value: $store.annualSpend
                        )
                    )
                }

                // MARK: - Section 3
                Section(header: sectionHeader("3. Additional Income")) {
                    fieldRow(
                        icon: "house.fill",
                        title: "Rental Income",
                        value: store.rentalIncome > 0 ? "\(fmtCurrency(store.rentalIncome))/yr" : "None",
                        destination: EditValueView(
                            title: "Rental Income",
                            subtitle: "Annual income from rental properties",
                            note: "Set to 0 if you don't have rental income",
                            min: 0, max: 200_000, step: 1_000,
                            format: .currency,
                            value: $store.rentalIncome
                        )
                    )

                    fieldRow(
                        icon: "calendar.badge.clock",
                        title: "Social Security Starts",
                        value: "Age \(store.socialSecurityAge)",
                        destination: EditValueView(
                            title: "Social Security Starts",
                            subtitle: "Age at which SS payments begin",
                            note: "62 = reduced · 67 = full · 70 = max benefit",
                            min: 62, max: 70, step: 1,
                            format: .age,
                            value: Binding(
                                get: { Double(store.socialSecurityAge) },
                                set: { store.socialSecurityAge = Int($0) }
                            )
                        )
                    )

                    fieldRow(
                        icon: "dollarsign.circle.fill",
                        title: "SS Annual Benefit",
                        value: store.socialSecurityAmt > 0 ? "\(fmtCurrency(store.socialSecurityAmt))/yr" : "None",
                        destination: EditValueView(
                            title: "SS Annual Benefit",
                            subtitle: "Expected Social Security benefit per year",
                            note: "Check ssa.gov for your personal estimate",
                            min: 0, max: 60_000, step: 500,
                            format: .currency,
                            value: $store.socialSecurityAmt
                        )
                    )
                }

                // MARK: - Section 4
                Section(header: sectionHeader("4. Investment Assumptions")) {
                    fieldRow(
                        icon: "chart.pie.fill",
                        title: "Bond vs Equity Mix",
                        value: "\(Int(store.bondAllocation))% bonds",
                        destination: EditValueView(
                            title: "Bond vs Equity Mix",
                            subtitle: "How your investment pot is allocated",
                            note: "Remainder goes to equity. e.g. 40 = 40% bonds, 60% equity",
                            min: 0, max: 100, step: 5,
                            format: .allocation,
                            value: $store.bondAllocation
                        )
                    )

                    fieldRow(
                        icon: "lock.shield.fill",
                        title: "Bond Return",
                        value: fmtPercent(store.bondReturn),
                        destination: EditValueView(
                            title: "Bond Return",
                            subtitle: "Expected annual return on bonds",
                            note: "5% realistic for Treasuries / investment-grade corporates",
                            min: 1.0, max: 8.0, step: 0.25,
                            format: .percent,
                            value: $store.bondReturn
                        )
                    )

                    fieldRow(
                        icon: "arrow.up.right.circle.fill",
                        title: "Equity Return",
                        value: fmtPercent(store.equityReturn),
                        destination: EditValueView(
                            title: "Equity Return",
                            subtitle: "Expected annual return on equities",
                            note: "S&P 500 ~10% nominal, ~7% real historically",
                            min: 2.0, max: 15.0, step: 0.5,
                            format: .percent,
                            value: $store.equityReturn
                        )
                    )

                    fieldRow(
                        icon: "gauge.with.dots.needle.67percent",
                        title: "Inflation Rate",
                        value: fmtPercent(store.inflationRate),
                        destination: EditValueView(
                            title: "Inflation Rate",
                            subtitle: "Expected annual price inflation",
                            note: "All spending grows at this rate. US avg ≈ 3%",
                            min: 1.0, max: 7.0, step: 0.25,
                            format: .percent,
                            value: $store.inflationRate
                        )
                    )
                }

                // Bottom padding for the sticky button
                Section { Color.clear.frame(height: 80) }
                    .listRowBackground(Color.clear)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(red: 0.04, green: 0.05, blue: 0.08))

            // MARK: - Show Results button
            NavigationLink {
                ResultsView(store: store)
            } label: {
                Text("Show Results")
                    .font(.system(.callout, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 0.06, green: 0.06, blue: 0.06))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.04, green: 0.05, blue: 0.08).opacity(0), Color(red: 0.04, green: 0.05, blue: 0.08)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 120)
                .allowsHitTesting(false)
            )
        }
        .navigationTitle("Retirement Planner")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingSavedPlans = true
                } label: {
                    Image(systemName: "folder")
                        .foregroundStyle(Color.gold)
                }
                .accessibilityLabel("Saved plans")
            }
        }
        .sheet(isPresented: $showingSavedPlans) {
            SavedPlansView(store: store)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(Color.gold)
            .kerning(0.5)
            .textCase(nil)
    }

    @ViewBuilder
    private func summaryChip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .kerning(0.5)
            Text(value)
                .font(.system(.callout, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(Color.gold)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func fieldRow<D: View>(icon: String, title: String, value: String, destination: D) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.gold.opacity(0.8))
                    .frame(width: 22)

                Text(title)
                    .foregroundStyle(.primary)

                Spacer()

                Text(value)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .listRowBackground(Color.white.opacity(0.04))
    }
}
