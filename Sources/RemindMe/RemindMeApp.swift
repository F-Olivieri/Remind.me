import SwiftUI

@main
struct RemindMeApp: App {
    @StateObject private var store = TaskStore()
    @StateObject private var windowController = FloatingWindowController()
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        MenuBarExtra {
            PopupView()
                .environmentObject(store)
                .environmentObject(windowController)
                .environmentObject(settings)
                .onAppear {
                    windowController.attach(store: store)
                    settings.applyActivationPolicy()
                }
        } label: {
            Image("MenuBarGlyph")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.window)
    }
}
