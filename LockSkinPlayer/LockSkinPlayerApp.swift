import SwiftUI

@main
struct LockSkinPlayerApp: App {
    @StateObject private var player = LocalPlayer()

    var body: some Scene {
        WindowGroup {
            PlayerView()
                .environmentObject(player)
        }
    }
}
