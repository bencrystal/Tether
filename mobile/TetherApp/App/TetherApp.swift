import SwiftUI
#if canImport(FamilyControls)
import FamilyControls
#endif

@main
struct TetherApp: App {
    @StateObject private var bleManager = BLEManager()
    @StateObject private var ruleStore = RuleStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(bleManager)
                .environmentObject(ruleStore)
                .onAppear {
                    requestFamilyControlsAuth()
                }
        }
    }

    private func requestFamilyControlsAuth() {
        #if canImport(FamilyControls)
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                print("[Auth] Family Controls authorized")
            } catch {
                print("[Auth] Family Controls denied or unavailable: \(error)")
            }
        }
        #else
        print("[Auth] FamilyControls not available on this platform")
        #endif
    }
}
