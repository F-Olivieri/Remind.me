import SwiftUI
import AppKit

@main
struct RemindMeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = TaskStore()
    @StateObject private var windowController = FloatingWindowController()
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup("Remind.me", id: "main") {
            PopupView()
                .environmentObject(store)
                .environmentObject(windowController)
                .environmentObject(settings)
                .onAppear {
                    windowController.attach(store: store, settings: settings)
                    settings.applyActivationPolicy()
                }
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            PopupView()
                .environmentObject(store)
                .environmentObject(windowController)
                .environmentObject(settings)
                .onAppear { windowController.attach(store: store, settings: settings) }
        } label: {
            Image("MenuBarGlyph")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let shouldShowDock = UserDefaults.standard.object(forKey: "showDockIcon") as? Bool ?? true
        NSApp.setActivationPolicy(shouldShowDock ? .regular : .accessory)
        if shouldShowDock {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for w in NSApp.windows where w.title == "Remind.me" {
                w.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return false
            }
        }
        return true
    }
}
