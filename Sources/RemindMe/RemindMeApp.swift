import SwiftUI

@main
struct RemindMeApp: App {
    @StateObject private var store = TaskStore()
    @StateObject private var windowController = FloatingWindowController()

    var body: some Scene {
        MenuBarExtra {
            PopupView()
                .environmentObject(store)
                .environmentObject(windowController)
                .onAppear { windowController.attach(store: store) }
        } label: {
            Image("MenuBarGlyph")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.window)
    }
}
