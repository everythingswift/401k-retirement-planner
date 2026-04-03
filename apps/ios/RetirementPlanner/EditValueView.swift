import SwiftUI

enum ValueFormat {
    case age          // "65 yrs"
    case currency     // "$65,000"
    case percent      // "7.0%"
    case allocation   // "40.0% bonds · 60.0% equity"
}

struct EditValueView: View {
    let title: String
    let subtitle: String
    let note: String?
    let min: Double
    let max: Double
    let step: Double
    let format: ValueFormat
    @Binding var value: Double

    @State private var textInput: String = ""
    @FocusState private var textFieldFocused: Bool

    init(
        title: String,
        subtitle: String,
        note: String? = nil,
        min: Double,
        max: Double,
        step: Double,
        format: ValueFormat,
        value: Binding<Double>
    ) {
        self.title = title
        self.subtitle = subtitle
        self.note = note
        self.min = min
        self.max = max
        self.step = step
        self.format = format
        self._value = value
    }

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.05, blue: 0.08).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: Current value hero
                    VStack(alignment: .leading, spacing: 6) {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(displayString(value))
                            .font(.system(size: 38, weight: .light, design: .monospaced))
                            .foregroundStyle(Color.gold)
                    }
                    .padding(.top, 8)

                    // MARK: Slider
                    VStack(spacing: 8) {
                        Slider(
                            value: $value,
                            in: min...max,
                            step: step
                        )
                        .tint(Color.gold)
                        .onChange(of: value) { _, newVal in
                            if !textFieldFocused {
                                textInput = rawString(newVal)
                            }
                        }

                        HStack {
                            Text(displayString(min))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.tertiary)
                            Spacer()
                            Text(displayString(max))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.tertiary)
                        }
                    }

                    // MARK: Text field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ENTER VALUE DIRECTLY")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .kerning(1)

                        HStack {
                            TextField("", text: $textInput)
                                .keyboardType(.decimalPad)
                                .focused($textFieldFocused)
                                .font(.system(.title3, design: .monospaced))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .onSubmit { commitText() }
                                .onChange(of: textFieldFocused) { _, focused in
                                    if !focused { commitText() }
                                }

                            if textFieldFocused {
                                Button("Done") {
                                    textFieldFocused = false
                                }
                                .font(.system(.callout, design: .monospaced))
                                .foregroundStyle(Color.gold)
                            }
                        }

                        if let note {
                            Text(note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text("Range: \(displayString(min)) – \(displayString(max))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    // MARK: Allocation visual (bonds only)
                    if case .allocation = format {
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.blue.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 8)
                            Rectangle()
                                .fill(Color.green.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 8)
                        }
                        .scaleEffect(x: 1, y: 1)
                        .clipShape(Capsule())
                        .overlay(alignment: .leading) {
                            GeometryReader { geo in
                                Capsule()
                                    .fill(Color.blue)
                                    .frame(width: geo.size.width * value / 100, height: 8)
                                    .animation(.easeInOut, value: value)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            textInput = rawString(value)
        }
    }

    // MARK: Helpers

    private func displayString(_ v: Double) -> String {
        switch format {
        case .age:        return "\(Int(v)) yrs"
        case .currency:   return fmtCurrency(v)
        case .percent:    return fmtPercent(v)
        case .allocation: return "\(Int(v))% bonds · \(100 - Int(v))% equity"
        }
    }

    private func rawString(_ v: Double) -> String {
        switch format {
        case .age:                    return "\(Int(v))"
        case .currency:               return "\(Int(v))"
        case .percent, .allocation:   return String(format: "%.2f", v)
        }
    }

    private func commitText() {
        let clean = textInput
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "%", with: "")
        if let parsed = Double(clean) {
            value = Swift.max(min, Swift.min(max, parsed))
        }
        textInput = rawString(value)
    }
}
