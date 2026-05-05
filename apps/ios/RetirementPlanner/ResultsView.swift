import SwiftUI
import Charts

struct ResultsView: View {
    let store: RetirementStore
    @Environment(PlanStore.self) private var planStore
    @AppStorage("savePrivacyNoticeSeen") private var privacyNoticeSeen = false

    @State private var selectedTab: ResultTab = .growth
    @State private var showingPrivacyAlert = false
    @State private var showingSavedToast = false

    enum ResultTab: String, CaseIterable {
        case growth  = "Growth"
        case income  = "Income"
        case table   = "Table"
    }

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.05, blue: 0.08).ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Summary strip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        statPill(label: "5-Yr Cash", value: fmtCurrency(store.initialCash))
                        statPill(label: "Invest Pot", value: fmtCurrency(store.investable), color: .green)
                        if let s5 = store.snapshotAt5 {
                            statPill(label: "@ Yr 5", value: fmtCurrency(s5.total))
                        }
                        if let s20 = store.snapshotAt20 {
                            statPill(label: "@ Yr 20", value: fmtCurrency(s20.total))
                        }
                        statPill(label: "Final", value: fmtCurrency(store.finalPortfolio),
                                 color: store.finalPortfolio >= store.totalPortfolio ? .green : .red)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color.white.opacity(0.03))

                // MARK: Tab picker
                Picker("View", selection: $selectedTab) {
                    ForEach(ResultTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // MARK: Content
                ScrollView {
                    switch selectedTab {
                    case .growth: PortfolioGrowthView(store: store)
                    case .income: IncomeVsSpendView(store: store)
                    case .table:  YearByYearView(store: store)
                    }
                }
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    handleSaveTap()
                } label: {
                    Text("Save")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(Color.gold)
                }
                .accessibilityLabel("Save plan")
            }
        }
        .alert("Saved Plans Stay on This Device", isPresented: $showingPrivacyAlert) {
            Button("Save Plan") {
                privacyNoticeSeen = true
                performSave()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Plans are saved on this device only. They're not synced or backed up. If you uninstall RetireWise, your saved plans are deleted.")
        }
        .overlay(alignment: .top) {
            if showingSavedToast {
                savedToast
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Save flow

    private func handleSaveTap() {
        if privacyNoticeSeen {
            performSave()
        } else {
            showingPrivacyAlert = true
        }
    }

    private func performSave() {
        let name = PlanStore.defaultName()
        let plan = SavedPlan(capturing: store, name: name)
        planStore.add(plan)

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        withAnimation(.easeInOut(duration: 0.2)) {
            showingSavedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.25)) {
                showingSavedToast = false
            }
        }
    }

    @ViewBuilder
    private var savedToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Saved")
                .font(.system(.callout, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.12))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
    }

    @ViewBuilder
    private func statPill(label: String, value: String, color: Color = Color.gold) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .kerning(0.5)
            Text(value)
                .font(.system(.callout, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Portfolio Growth Chart

private struct PortfolioGrowthView: View {
    let store: RetirementStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Portfolio buckets to age 100 · cash refilled every 5 years")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            Chart {
                ForEach(store.snapshots, id: \.yr) { s in
                    LineMark(
                        x: .value("Age", s.age),
                        y: .value("Value", s.total),
                        series: .value("Type", "Total")
                    )
                    .foregroundStyle(.white.opacity(0.9))
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    LineMark(
                        x: .value("Age", s.age),
                        y: .value("Value", s.equity),
                        series: .value("Type", "Equity")
                    )
                    .foregroundStyle(Color.green)

                    LineMark(
                        x: .value("Age", s.age),
                        y: .value("Value", s.bonds),
                        series: .value("Type", "Bonds")
                    )
                    .foregroundStyle(Color.blue)

                    LineMark(
                        x: .value("Age", s.age),
                        y: .value("Value", s.cash),
                        series: .value("Type", "Cash")
                    )
                    .foregroundStyle(Color.gold)
                }
            }
            .chartXScale(domain: store.retireAge...99)
            .chartXAxis {
                AxisMarks(values: .stride(by: 5)) {
                    AxisValueLabel().foregroundStyle(Color.secondary)
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                }
            }
            .chartYAxis {
                AxisMarks { val in
                    AxisValueLabel {
                        if let v = val.as(Double.self) {
                            Text(fmtCurrency(v))
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                }
            }
            .chartLegend(position: .bottom, alignment: .leading)
            .frame(height: 260)
            .padding(.horizontal, 16)

            // MARK: Milestone cards
            HStack(spacing: 10) {
                ForEach([5, 20, store.snapshots.count - 1], id: \.self) { idx in
                    if idx >= 0, idx < store.snapshots.count {
                        milestoneCard(snapshot: store.snapshots[idx])
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .padding(.top, 16)
    }

    @ViewBuilder
    private func milestoneCard(snapshot: BucketSnapshot) -> some View {
        let grew = snapshot.total >= store.totalPortfolio
        VStack(alignment: .leading, spacing: 4) {
            Text("Age \(snapshot.age)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .kerning(0.3)
            Text(fmtCurrency(snapshot.total))
                .font(.system(.callout, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(grew ? .green : .red)
                .monospacedDigit()
            Text("\(grew ? "▲" : "▼") \(fmtCurrency(abs(snapshot.total - store.totalPortfolio)))")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(grew ? Color.green.opacity(0.25) : Color.red.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Income vs Spend Chart

private struct IncomeVsSpendView: View {
    let store: RetirementStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Income sources vs. total spending (inflation-adjusted, nominal dollars)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            Chart {
                ForEach(store.snapshots, id: \.yr) { s in
                    LineMark(
                        x: .value("Age", s.age),
                        y: .value("Value", s.spend),
                        series: .value("Type", "Spending")
                    )
                    .foregroundStyle(Color.red.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    LineMark(
                        x: .value("Age", s.age),
                        y: .value("Value", s.totalReturn),
                        series: .value("Type", "Invest Return")
                    )
                    .foregroundStyle(Color.green)

                    LineMark(
                        x: .value("Age", s.age),
                        y: .value("Value", s.rental),
                        series: .value("Type", "Rental")
                    )
                    .foregroundStyle(Color.gold)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))

                    LineMark(
                        x: .value("Age", s.age),
                        y: .value("Value", s.ss),
                        series: .value("Type", "Social Security")
                    )
                    .foregroundStyle(Color.purple)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                }

                if let ssSnap = store.snapshots.first(where: { $0.age == store.socialSecurityAge }) {
                    RuleMark(x: .value("SS Age", ssSnap.age))
                        .foregroundStyle(Color.purple.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("SS @ \(ssSnap.age)")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(Color.purple)
                        }
                }
            }
            .chartXScale(domain: store.retireAge...99)
            .chartXAxis {
                AxisMarks(values: .stride(by: 5)) {
                    AxisValueLabel().foregroundStyle(Color.secondary)
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                }
            }
            .chartYAxis {
                AxisMarks { val in
                    AxisValueLabel {
                        if let v = val.as(Double.self) {
                            Text(fmtCurrency(v))
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                }
            }
            .chartLegend(position: .bottom, alignment: .leading)
            .frame(height: 280)
            .padding(.horizontal, 16)

            // MARK: Year 1 breakdown
            VStack(alignment: .leading, spacing: 0) {
                Text("YEAR 1 BREAKDOWN")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .kerning(1)
                    .padding(.bottom, 10)

                incomeRow("Bond Gains",     fmtCurrency(store.bondAmt * store.bondReturn / 100),     .blue)
                Divider().opacity(0.1)
                incomeRow("Equity Gains",   fmtCurrency(store.equityAmt * store.equityReturn / 100), .green)
                Divider().opacity(0.1)
                incomeRow("Rental Income",  fmtCurrency(store.rentalIncome),                          Color.gold)
                Divider().opacity(0.1)
                incomeRow("Social Security",
                           store.retireAge >= store.socialSecurityAge ? fmtCurrency(store.socialSecurityAmt) : "Not yet",
                           .purple)
                Divider().opacity(0.2).padding(.vertical, 4)
                incomeRow("vs. Annual Spend", fmtCurrency(store.annualSpend), .red)
            }
            .padding(16)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .padding(.top, 16)
    }

    @ViewBuilder
    private func incomeRow(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary).font(.subheadline)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Year By Year Table

private struct YearByYearView: View {
    let store: RetirementStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Green rows = cash refill from bonds + equity")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            // Header
            HStack(spacing: 0) {
                tableCell("Age",    width: 44, header: true)
                tableCell("Bonds",  width: 70, header: true)
                tableCell("Equity", width: 70, header: true)
                tableCell("Cash",   width: 64, header: true)
                tableCell("Total",  width: 72, header: true)
                tableCell("Spend",  width: 64, header: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06))

            ForEach(store.snapshots, id: \.yr) { s in
                let isRefill = (s.yr + 1) % 5 == 0 && s.yr < store.snapshots.count - 1
                let isGood   = s.total >= store.totalPortfolio

                HStack(spacing: 0) {
                    Text("\(s.age)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(isRefill ? Color.green : .white)
                        .fontWeight(isRefill ? .bold : .semibold)
                        .frame(width: 44, alignment: .trailing)

                    Text(fmtCurrency(s.bonds))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.blue)
                        .frame(width: 70, alignment: .trailing)

                    Text(fmtCurrency(s.equity))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.green)
                        .frame(width: 70, alignment: .trailing)

                    Text(fmtCurrency(s.cash))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color.gold)
                        .frame(width: 64, alignment: .trailing)

                    Text(fmtCurrency(s.total))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(isGood ? Color.green : Color.red)
                        .fontWeight(.bold)
                        .frame(width: 72, alignment: .trailing)

                    Text(fmtCurrency(s.spend))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color.red.opacity(0.8))
                        .frame(width: 64, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(isRefill ? Color.green.opacity(0.06) : Color.clear)

                Divider().opacity(0.07)
            }
        }
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private func tableCell(_ text: String, width: CGFloat, header: Bool = false) -> some View {
        Text(text)
            .font(.system(size: header ? 9 : 11, design: .monospaced))
            .foregroundStyle(header ? Color.gold : .primary)
            .fontWeight(header ? .semibold : .regular)
            .kerning(header ? 0.5 : 0)
            .frame(width: width, alignment: .trailing)
    }
}
