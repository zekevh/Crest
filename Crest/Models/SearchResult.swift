import Foundation

struct SearchResult: Identifiable {
    var id: String { symbol }
    let symbol: String
    let shortName: String?
    let exchange: String?
    let quoteType: String?
}

struct YFSearchResponse: Codable {
    let quotes: [YFSearchQuote]
}

struct YFSearchQuote: Codable {
    let symbol: String
    let shortname: String?
    let exchange: String?
    let quoteType: String?
}
