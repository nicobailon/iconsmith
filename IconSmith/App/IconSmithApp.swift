import SwiftUI

@main
struct IconSmithApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Apply Icon to Selection") {
                }
                .keyboardShortcut("i", modifiers: .command)
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "iconsmith" else { return }
        
        switch url.host {
        case "apply":
            if let query = url.query,
               let filesParam = query.components(separatedBy: "=").last {
                let files = filesParam.components(separatedBy: ",")
                    .compactMap { $0.removingPercentEncoding }
                    .compactMap { URL(string: $0) }
                appState.pendingFiles = files
                appState.showIconPicker = true
            }
        default:
            break
        }
    }
}
