import Foundation

struct QuoteService {
    func fetch(symbols: [String]) async throws -> [Quote] {
        try await withThrowingTaskGroup(of: Quote?.self) { group in
            for symbol in symbols {
                group.addTask { try await fetchOne(symbol) }
            }
            var results: [String: Quote] = [:]
            for try await quote in group {
                if let q = quote { results[q.symbol] = q }
            }
            return symbols.compactMap { results[$0] }
        }
    }

    /// Returns the conversion rate: 1 USD → preferredCurrency.
    /// For EURUSD=X (price = USD per 1 EUR), invert to get EUR per 1 USD.
    func fetchExchangeRate(for currency: PreferredCurrency) async -> Double? {
        guard let symbol = currency.yahooSymbol else { return 1.0 }
        guard let quote = try? await fetchOne(symbol) else { return nil }
        return quote.price > 0 ? (1.0 / quote.price) : nil
    }

    private func fetchOne(_ symbol: String) async throws -> Quote? {
        guard let url = URL(string: "https://query2.finance.yahoo.com/v8/finance/chart/\(symbol)?interval=1d&range=1d") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(YFChartResponse.self, from: data)

        guard let meta = response.chart.result?.first?.meta else { return nil }

        let change = meta.regularMarketPrice - meta.chartPreviousClose
        let changePercent = meta.chartPreviousClose != 0
            ? (change / meta.chartPreviousClose) * 100
            : 0

        let sym = meta.symbol
        let isPair = sym.contains("-") || sym.contains("=")

        return Quote(
            symbol: sym,
            shortName: meta.shortName,
            price: meta.regularMarketPrice,
            change: change,
            changePercent: changePercent,
            dayHigh: meta.regularMarketDayHigh,
            dayLow: meta.regularMarketDayLow,
            currency: meta.currency,
            isPair: isPair,
            tradingPeriod: meta.currentTradingPeriod
        )
    }
}
