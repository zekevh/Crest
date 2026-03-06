import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: CrestViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Carousel speed
            HStack(spacing: 6) {
                ForEach([2, 3, 5], id: \.self) { preset in
                    Button("\(preset)s") { vm.setCarouselSpeed(preset) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(vm.carouselSpeed == preset ? .accentColor : .secondary)
                }
                Spacer()
                Stepper(
                    value: Binding(get: { vm.carouselSpeed }, set: { vm.setCarouselSpeed($0) }),
                    in: 1...60
                ) {
                    Text("\(vm.carouselSpeed)s")
                        .monospacedDigit()
                        .frame(width: 30, alignment: .center)
                        .font(.callout)
                }
            }

            // Refresh interval
            Picker("Refresh", selection: $vm.refreshInterval) {
                Text("1 min").tag(60)
                Text("5 min").tag(300)
                Text("15 min").tag(900)
            }
            .pickerStyle(.segmented)
            .onChange(of: vm.refreshInterval) { _, newValue in
                vm.setRefreshInterval(newValue)
            }

            // Currency
            Picker("Currency", selection: $vm.preferredCurrency) {
                ForEach(PreferredCurrency.allCases, id: \.self) { c in
                    Text(c.rawValue).tag(c)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: vm.preferredCurrency) { _, newValue in
                vm.setPreferredCurrency(newValue)
            }

            Divider()

            // Launch at login
            Toggle(isOn: Binding(
                get: { vm.isLaunchAtLoginEnabled },
                set: { _ in vm.toggleLaunchAtLogin() }
            )) {
                Text("Launch at login")
                    .font(.callout)
            }
            .toggleStyle(.checkbox)
        }
        .padding(12)
    }
}
