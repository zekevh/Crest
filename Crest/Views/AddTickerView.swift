import SwiftUI

struct AddTickerView: View {
    @EnvironmentObject var vm: CrestViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                TextField("Add ticker...", text: $vm.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .onChange(of: vm.searchQuery) { _, newValue in
                        vm.search(newValue)
                    }
                if !vm.searchQuery.isEmpty {
                    Button {
                        vm.searchQuery = ""
                        vm.searchResults = []
                        vm.isSearching = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if vm.isSearching {
                HStack {
                    ProgressView().scaleEffect(0.7)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
            } else if !vm.searchQuery.isEmpty && vm.searchResults.isEmpty {
                Text("No results")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
            } else if !vm.searchResults.isEmpty {
                VStack(spacing: 0) {
                    ForEach(vm.searchResults.prefix(5)) { result in
                        Button {
                            vm.addTicker(result.symbol)
                            vm.searchQuery = ""
                            vm.searchResults = []
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(result.symbol)
                                        .font(.system(.callout, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    if let name = result.shortName {
                                        Text(name)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if let exchange = result.exchange {
                                    Text(exchange)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .contentShape(Rectangle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 4)
            }
        }
    }
}
