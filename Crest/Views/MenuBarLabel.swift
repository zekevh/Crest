import SwiftUI

struct MenuBarLabel: View {
    @EnvironmentObject var vm: CrestViewModel

    private var currentSymbol: String? {
        guard !vm.watchlist.isEmpty else { return nil }
        return vm.watchlist[min(vm.currentCarouselIndex, vm.watchlist.count - 1)]
    }

    var body: some View {
        if let symbol = currentSymbol {
            let quote = vm.quotes[symbol]
            let price = quote.map { vm.formatPrice($0.price, currency: $0.currency, isPair: $0.isPair) } ?? "—"
            let pct = quote.map { q in
                String(format: " %@%.2f%%", q.changePercent >= 0 ? "▲" : "▼", abs(q.changePercent))
            } ?? ""

            Text("\(symbol) \(price)\(pct)")
                .opacity(vm.lastFetchFailed && quote != nil ? 0.5 : 1.0)
        } else {
            Text("Crest")
        }
    }
}
