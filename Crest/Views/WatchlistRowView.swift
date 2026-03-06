import SwiftUI

struct WatchlistRowView: View {
    @EnvironmentObject var vm: CrestViewModel
    let symbol: String
    let quote: Quote?

    private var isStale: Bool { quote?.isStale ?? false }

    private var priceString: String {
        guard let q = quote else { return "—" }
        return vm.formatPrice(q.price, currency: q.currency, isPair: q.isPair)
    }

    private var changeString: String {
        guard let q = quote else { return "" }
        let arrow = q.changePercent >= 0 ? "▲" : "▼"
        return String(format: "%@ %.2f%%", arrow, abs(q.changePercent))
    }

    private var changeColor: Color {
        guard let q = quote else { return .secondary }
        if q.changePercent > 0 { return .green }
        if q.changePercent < 0 { return .red }
        return .secondary
    }

    private func formatted(_ value: Double?) -> String {
        guard let value else { return "—" }
        return vm.formatPrice(value, currency: quote?.currency, isPair: quote?.isPair ?? false)
    }

    var body: some View {
        VStack(spacing: 3) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(symbol)
                        .font(.system(.callout, weight: .semibold))
                    Text(quote?.shortName ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(priceString)
                        .font(.system(.callout, design: .monospaced))
                        .opacity(isStale ? 0.5 : 1.0)
                    Text(changeString)
                        .font(.caption)
                        .foregroundStyle(changeColor)
                        .opacity(isStale ? 0.5 : 1.0)
                }
            }
            if let q = quote {
                HStack {
                    Text("H \(formatted(q.dayHigh))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("L \(formatted(q.dayLow))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
