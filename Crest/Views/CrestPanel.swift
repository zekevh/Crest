import SwiftUI

struct CrestPanel: View {
    @EnvironmentObject var vm: CrestViewModel

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if vm.watchlist.isEmpty {
                    emptyState
                } else {
                    watchlistSection
                }
                Divider()
                AddTickerView()
                Divider()
                SettingsView()
            }
            .frame(width: 300)

            Button("Quit") { NSApp.terminate(nil) }
                .keyboardShortcut("q", modifiers: .command)
                .hidden()
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer().frame(height: 16)
            Text("Add a ticker to get started")
                .font(.callout)
                .foregroundStyle(.secondary)
            Image(systemName: "arrow.down")
                .foregroundStyle(.secondary)
            Spacer().frame(height: 16)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Watchlist section

    private var watchlistSection: some View {
        VStack(spacing: 0) {
            HStack {
                if vm.lastFetchFailed {
                    Text("Stale data")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else if let last = vm.lastRefreshed {
                    Text(timeAgo(from: last))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else if vm.isRefreshing {
                    Text("Refreshing...")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    Task { await vm.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .disabled(vm.isRefreshing)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 2)

            if let status = vm.marketStatus {
                HStack(spacing: 5) {
                    Circle()
                        .fill(status.dotColor)
                        .frame(width: 6, height: 6)
                    Text(status.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
            }

            List {
                ForEach(vm.watchlist, id: \.self) { symbol in
                    WatchlistRowView(symbol: symbol, quote: vm.quotes[symbol])
                        .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                }
                .onDelete { vm.removeTicker(at: $0) }
                .onMove { vm.move(from: $0, to: $1) }
            }
            .listStyle(.plain)
            .frame(maxHeight: 360)
        }
    }

    private func timeAgo(from date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "Just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        return "\(seconds / 3600)h ago"
    }
}
