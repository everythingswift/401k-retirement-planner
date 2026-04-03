import SwiftUI

struct DisclaimerView: View {
    let onAccept: () -> Void

    private let bucketSteps: [(String, String, String)] = [
        ("Year 0",      "Set aside 5 years of net living expenses as cash. The rest goes to bonds + equity.", "circle.fill"),
        ("Years 1–5",   "Spend from cash. Your investment pot grows untouched.",                              "chart.line.uptrend.xyaxis"),
        ("End of Yr 5", "Withdraw the next 5 years of expenses from bonds + equity into cash.",               "arrow.left.arrow.right"),
        ("Repeat",      "Cash refilled every 5 years. Your pot keeps compounding between withdrawals.",        "repeat"),
    ]

    private let disclaimers: [(String, String, String)] = [
        ("exclamationmark.triangle.fill", "Not financial advice",
         "This tool is for informational purposes only. Always consult a licensed financial advisor before making retirement decisions."),
        ("chart.bar.xaxis",               "Returns are not guaranteed",
         "Bond and equity returns are variable. Historical performance does not guarantee future results."),
        ("cross.case.fill",               "Unexpected expenses excluded",
         "Healthcare costs, emergencies, and one-time large expenses are not modelled. Maintain a separate buffer."),
        ("doc.text.fill",                 "Taxes not included",
         "Capital gains, income tax, RMDs, and state taxes are not factored in. Your real take-home will differ."),
        ("wand.and.stars",                "Projections are estimates",
         "Outputs are based on your inputs and simplified assumptions. Real-world outcomes will vary significantly."),
    ]

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.05, blue: 0.08)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BEFORE YOU BEGIN")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Color.gold)
                            .kerning(2)

                        Text("The 5-Year\nBucket Strategy")
                            .font(.system(size: 30, weight: .light))
                            .foregroundStyle(.white)
                            .lineSpacing(4)

                        Text("Rather than withdrawing a fixed percentage annually, this planner keeps your wealth actively growing in bonds and equity throughout retirement. You withdraw only what you need, every 5 years.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 48)
                    .padding(.bottom, 24)

                    // MARK: Bucket steps
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(bucketSteps.enumerated()), id: \.offset) { i, step in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: step.2)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.gold)
                                    .frame(width: 24)
                                    .padding(.top, 2)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(step.0)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(Color.gold)
                                        .fontWeight(.semibold)
                                    Text(step.1)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineSpacing(3)
                                }
                            }
                            .padding(.vertical, 10)

                            if i < bucketSteps.count - 1 {
                                Divider().opacity(0.15).padding(.leading, 38)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16)

                    // MARK: Disclaimers
                    VStack(alignment: .leading, spacing: 4) {
                        Text("IMPORTANT DISCLAIMERS")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Color(red: 0.97, green: 0.53, blue: 0.53))
                            .kerning(1.5)
                            .padding(.bottom, 8)

                        ForEach(disclaimers, id: \.1) { icon, title, desc in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: icon)
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color(red: 0.97, green: 0.53, blue: 0.53))
                                    .frame(width: 24)
                                    .padding(.top, 1)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                    Text(desc)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineSpacing(3)
                                }
                            }
                            .padding(.vertical, 10)
                            Divider().opacity(0.1)
                        }
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // MARK: CTA
                    Button(action: onAccept) {
                        Text("I Understand — Start Planning")
                            .font(.system(.callout, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundStyle(Color(red: 0.06, green: 0.06, blue: 0.06))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 28)
                }
            }
        }
    }
}

extension Color {
    static let gold = Color(red: 0.94, green: 0.75, blue: 0.25)
}
