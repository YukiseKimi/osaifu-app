import OsaifuCore
import SwiftUI

/// The amount, set by the Digital Crown.
///
/// Apple's guide asks for a touch control beside any crown action, so the two
/// buttons do the same job as the crown. There is no keyboard on the watch.
struct AmountView: View {
    let currencyCode: String
    @Binding var minorUnits: Int

    /// The crown reports a float. The view keeps it beside the amount and
    /// rounds it, so the amount stays a whole number of minor units.
    @State private var crown = 0.0

    private var money: Money { Money(minorUnits: minorUnits, currencyCode: currencyCode) }

    var body: some View {
        VStack(spacing: 8) {
            Text(money.formatted())
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.snappy, value: minorUnits)
                .focusable()
                .digitalCrownRotation(
                    $crown,
                    from: 0,
                    through: Double(AmountStep.maximum),
                    by: Double(AmountStep.of(minorUnits)),
                    sensitivity: .medium,
                    isContinuous: false
                )
                .accessibilityLabel("Amount")
                .accessibilityValue(money.formatted())

            HStack(spacing: 10) {
                stepButton("minus", to: AmountStep.down(from: minorUnits))
                stepButton("plus", to: AmountStep.up(from: minorUnits))
            }
        }
        .onAppear { crown = Double(minorUnits) }
        .onChange(of: crown) { _, turned in
            minorUnits = Int(turned.rounded())
        }
    }

    private func stepButton(_ symbol: String, to value: Int) -> some View {
        Button {
            minorUnits = value
            // The crown holds its own position, so move it with the amount.
            crown = Double(value)
        } label: {
            Image(systemName: symbol)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(symbol == "plus" ? "More" : "Less")
    }
}

#Preview {
    @Previewable @State var minorUnits = 1_280
    return AmountView(currencyCode: "JPY", minorUnits: $minorUnits)
}
