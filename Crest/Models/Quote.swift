import Foundation

struct Quote: Identifiable {
    var id: String { symbol }
    let symbol: String
    let shortName: String?
    let price: Double
    let change: Double
    let changePercent: Double
    let dayHigh: Double?
    let dayLow: Double?
    let currency: String?
    var isStale: Bool = false
    /// True for forex/crypto pairs (e.g. BTC-USD, EURUSD=X) — price should never be currency-converted.
    let isPair: Bool
    let tradingPeriod: YFTradingPeriods?
}

// MARK: - Yahoo Finance v8 chart API

struct YFChartResponse: Codable {
    let chart: YFChartResult
}

struct YFChartResult: Codable {
    let result: [YFChartEntry]?
}

struct YFChartEntry: Codable {
    let meta: YFChartMeta
}

struct YFChartMeta: Codable {
    let symbol: String
    let shortName: String?
    let currency: String?
    let regularMarketPrice: Double
    let regularMarketDayHigh: Double?
    let regularMarketDayLow: Double?
    let chartPreviousClose: Double
    let currentTradingPeriod: YFTradingPeriods?
}

struct YFTradingPeriods: Codable {
    let pre: YFTradingSession?
    let regular: YFTradingSession
    let post: YFTradingSession?
}

struct YFTradingSession: Codable {
    let start: TimeInterval
    let end: TimeInterval
    let timezone: String
}
