import Foundation
import ServiceManagement

@MainActor
final class CrestViewModel: ObservableObject {

    // MARK: - Watchlist & quotes

    @Published var watchlist: [String] = []
    @Published var quotes: [String: Quote] = [:]
    @Published var isRefreshing = false
    @Published var lastFetchFailed = false
    @Published var lastRefreshed: Date? = nil

    // MARK: - Menu bar display

    @Published var currentCarouselIndex = 0

    // MARK: - Settings

    @Published var carouselSpeed: Int = 3
    @Published var refreshInterval: Int = 300
    @Published var preferredCurrency: PreferredCurrency = .usd
    @Published var isLaunchAtLoginEnabled = false

    // MARK: - Exchange rate (for currency conversion)

    @Published var exchangeRate: Double = 1.0   // 1 USD → preferredCurrency

    // MARK: - Market status

    var marketStatus: MarketStatus? {
        guard let periods = quotes.values.first(where: { !$0.isPair })?.tradingPeriod else { return nil }
        return MarketStatus(periods: periods)
    }

    // MARK: - Search

    @Published var searchQuery = ""
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false

    // MARK: - Private

    private var refreshTimer: Timer?
    private var carouselTimer: Timer?
    private let quoteService = QuoteService()
    private let searchService = SearchService()
    private var searchTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        loadSettings()
        isLaunchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        if !watchlist.isEmpty {
            Task { await refresh() }
        }
        Task { await fetchExchangeRate() }
        startTimers()
    }

    deinit {
        refreshTimer?.invalidate()
        carouselTimer?.invalidate()
    }

    // MARK: - Refresh

    func refresh() async {
        guard !watchlist.isEmpty else { return }
        isRefreshing = true
        do {
            let fetched = try await quoteService.fetch(symbols: watchlist)
            for quote in fetched {
                quotes[quote.symbol] = quote
            }
            lastFetchFailed = false
            lastRefreshed = Date()
        } catch {
            lastFetchFailed = true
            for key in quotes.keys {
                quotes[key]?.isStale = true
            }
        }
        isRefreshing = false
    }

    func fetchExchangeRate() async {
        let rate = await quoteService.fetchExchangeRate(for: preferredCurrency)
        exchangeRate = rate ?? 1.0
    }

    // MARK: - Price conversion

    func convertedPrice(_ price: Double, nativeCurrency: String?) -> Double {
        guard preferredCurrency != .usd else { return price }
        // Only convert USD-denominated assets
        guard nativeCurrency == "USD" else { return price }
        return price * exchangeRate
    }

    func currencySymbol(for nativeCurrency: String?) -> String {
        if preferredCurrency == .usd || nativeCurrency != "USD" {
            return nativeCurrency.map { currencySymbolMap[$0] ?? $0 } ?? "$"
        }
        return preferredCurrency.symbol
    }

    private static let priceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    private static let satsFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    func formatPrice(_ price: Double, currency: String?, isPair: Bool = false) -> String {
        // Forex/crypto pairs keep their native price; only convert regular assets
        let converted = isPair ? price : convertedPrice(price, nativeCurrency: currency)

        // BTC display: use satoshis for sub-cent BTC values
        if !isPair && preferredCurrency == .btc && currency == "USD" {
            if converted < 0.01 {
                let sats = Int(converted * 100_000_000)
                let formatted = Self.satsFormatter.string(from: NSNumber(value: sats)) ?? "\(sats)"
                return "\(formatted) sats"
            }
            let formatted = Self.priceFormatter.string(from: NSNumber(value: converted)) ?? String(format: "%.2f", converted)
            return "₿\(formatted)"
        }

        let sym = isPair
            ? (currency.flatMap { currencySymbolMap[$0] } ?? "$")
            : currencySymbol(for: currency)
        let formatted = Self.priceFormatter.string(from: NSNumber(value: converted)) ?? String(format: "%.2f", converted)
        return "\(sym)\(formatted)"
    }

    private let currencySymbolMap: [String: String] = [
        "USD": "$", "EUR": "€", "GBP": "£", "JPY": "¥",
        "CAD": "C$", "AUD": "A$", "CHF": "Fr"
    ]

    // MARK: - Watchlist management

    func addTicker(_ symbol: String) {
        guard !watchlist.contains(symbol) else { return }
        watchlist.append(symbol)
        saveSettings()
        Task { await refresh() }
    }

    func removeTicker(at offsets: IndexSet) {
        let removedSymbols = offsets.map { watchlist[$0] }
        watchlist.remove(atOffsets: offsets)
        for symbol in removedSymbols {
            quotes.removeValue(forKey: symbol)
        }
        if !watchlist.isEmpty && currentCarouselIndex >= watchlist.count {
            currentCarouselIndex = 0
        } else if watchlist.isEmpty {
            currentCarouselIndex = 0
        }
        saveSettings()
    }

    func move(from source: IndexSet, to destination: Int) {
        watchlist.move(fromOffsets: source, toOffset: destination)
        saveSettings()
    }

    // MARK: - Search

    func search(_ query: String) {
        searchTask?.cancel()
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            isSearching = true
            do {
                let results = try await searchService.search(query)
                guard !Task.isCancelled else { return }
                searchResults = results
            } catch {
                if !Task.isCancelled {
                    searchResults = []
                }
            }
            isSearching = false
        }
    }

    // MARK: - Timers

    func startTimers() {
        stopTimers()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(refreshInterval), repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
        if !watchlist.isEmpty {
            carouselTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(carouselSpeed), repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.advanceCarousel()
                }
            }
        }
    }


    func stopTimers() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        carouselTimer?.invalidate()
        carouselTimer = nil
    }

    private func advanceCarousel() {
        guard !watchlist.isEmpty else { return }
        currentCarouselIndex = (currentCarouselIndex + 1) % watchlist.count
    }

    // MARK: - Settings setters

    func setCarouselSpeed(_ speed: Int) {
        carouselSpeed = speed
        saveSettings()
        startTimers()
    }

    func setRefreshInterval(_ interval: Int) {
        refreshInterval = interval
        saveSettings()
        startTimers()
    }

    func setPreferredCurrency(_ currency: PreferredCurrency) {
        preferredCurrency = currency
        saveSettings()
        Task { await fetchExchangeRate() }
    }

    func toggleLaunchAtLogin() {
        do {
            if isLaunchAtLoginEnabled {
                try SMAppService.mainApp.unregister()
                isLaunchAtLoginEnabled = false
            } else {
                try SMAppService.mainApp.register()
                isLaunchAtLoginEnabled = true
            }
        } catch {
            print("CrestViewModel: SMAppService error: \(error)")
        }
    }

    // MARK: - Persistence

    func saveSettings() {
        UserDefaults.standard.set(watchlist, forKey: "crest.watchlist")
        UserDefaults.standard.set(carouselSpeed, forKey: "crest.carouselSpeed")
        UserDefaults.standard.set(refreshInterval, forKey: "crest.refreshInterval")
UserDefaults.standard.set(preferredCurrency.rawValue, forKey: "crest.preferredCurrency")
    }

    private func loadSettings() {
        if let saved = UserDefaults.standard.array(forKey: "crest.watchlist") as? [String], !saved.isEmpty {
            watchlist = saved
        } else {
            watchlist = ["AAPL", "GOOGL", "BTC-USD"]
        }

        let speed = UserDefaults.standard.integer(forKey: "crest.carouselSpeed")
        carouselSpeed = speed > 0 ? speed : 3

        let interval = UserDefaults.standard.integer(forKey: "crest.refreshInterval")
        refreshInterval = interval > 0 ? interval : 300

        if let rawCurrency = UserDefaults.standard.string(forKey: "crest.preferredCurrency"),
           let currency = PreferredCurrency(rawValue: rawCurrency) {
            preferredCurrency = currency
        }
    }
}
