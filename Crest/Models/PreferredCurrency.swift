import Foundation

enum PreferredCurrency: String, CaseIterable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case btc = "BTC"

    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .btc: return "₿"
        }
    }

    /// Yahoo Finance symbol to fetch 1 USD → this currency
    var yahooSymbol: String? {
        switch self {
        case .usd: return nil
        case .eur: return "EURUSD=X"   // EUR per 1 USD → invert
        case .gbp: return "GBPUSD=X"   // GBP per 1 USD → invert
        case .btc: return "BTC-USD"    // USD per 1 BTC → invert
        }
    }
}
