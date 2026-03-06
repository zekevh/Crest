import SwiftUI

@main
struct CrestApp: App {
    @StateObject private var vm = CrestViewModel()

    var body: some Scene {
        MenuBarExtra(
            content: { CrestPanel().environmentObject(vm) },
            label: { MenuBarLabel().environmentObject(vm) }
        )
        .menuBarExtraStyle(.window)
    }
}
