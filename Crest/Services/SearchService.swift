import Foundation

struct SearchService {
    private let allowedTypes: Set<String> = ["EQUITY", "ETF", "CRYPTOCURRENCY"]

    func search(_ query: String) async throws -> [SearchResult] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "https://query1.finance.yahoo.com/v1/finance/search?q=\(encoded)&newsCount=0&enableFuzzyQuery=false&enableCb=false") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(YFSearchResponse.self, from: data)

        return response.quotes
            .filter { allowedTypes.contains($0.quoteType ?? "") }
            .map { SearchResult(symbol: $0.symbol, shortName: $0.shortname, exchange: $0.exchange, quoteType: $0.quoteType) }
    }
}
