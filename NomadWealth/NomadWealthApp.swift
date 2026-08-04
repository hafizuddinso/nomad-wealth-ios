import SwiftUI
import UIKit

extension Notification.Name {
    static let nomadShareApp = Notification.Name("nomad.shareApp")
    static let nomadAddTransaction = Notification.Name("nomad.addTransaction")
    static let nomadOpenDashboard = Notification.Name("nomad.openDashboard")
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.shortcutItems = [
            UIApplicationShortcutItem(
                type: "com.hafizuddin.nomadwealth.share",
                localizedTitle: "Share Nomad Wealth",
                localizedSubtitle: "AirDrop or send the app link",
                icon: UIApplicationShortcutIcon(systemImageName: "square.and.arrow.up")
            ),
            UIApplicationShortcutItem(
                type: "com.hafizuddin.nomadwealth.addTransaction",
                localizedTitle: "Add Transaction",
                localizedSubtitle: "Record Money In or Money Out",
                icon: UIApplicationShortcutIcon(systemImageName: "plus.circle")
            ),
            UIApplicationShortcutItem(
                type: "com.hafizuddin.nomadwealth.dashboard",
                localizedTitle: "Open Dashboard",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "house")
            )
        ]
        return true
    }

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        switch shortcutItem.type {
        case "com.hafizuddin.nomadwealth.share":
            NotificationCenter.default.post(name: .nomadShareApp, object: nil)
            completionHandler(true)
        case "com.hafizuddin.nomadwealth.addTransaction":
            NotificationCenter.default.post(name: .nomadAddTransaction, object: nil)
            completionHandler(true)
        case "com.hafizuddin.nomadwealth.dashboard":
            NotificationCenter.default.post(name: .nomadOpenDashboard, object: nil)
            completionHandler(true)
        default:
            completionHandler(false)
        }
    }
}

@main
struct NomadWealthApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = FinanceStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(store.appearance.colorScheme)
        }
    }
}
