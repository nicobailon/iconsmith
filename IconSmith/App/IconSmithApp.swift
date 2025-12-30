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
            CommandGroup(replacing: .newItem) {}
            
            CommandGroup(after: .sidebar) {
                Divider()
                
                Button("Dashboard") {
                    navigateTo(.dashboard)
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Folders") {
                    navigateTo(.folders)
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Button("Icon Library") {
                    navigateTo(.library)
                }
                .keyboardShortcut("3", modifiers: .command)
                
                Button("Presets") {
                    navigateTo(.presets)
                }
                .keyboardShortcut("4", modifiers: .command)
                
                Button("Generate") {
                    navigateTo(.generate)
                }
                .keyboardShortcut("5", modifiers: .command)
            }
            
            CommandGroup(after: .undoRedo) {
                Button("Undo Last Icon Change") {
                    _ = appState.undoManager.undo()
                }
                .keyboardShortcut("z", modifiers: [.command, .option])
                .disabled(!appState.undoManager.canUndo)
            }
            
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    navigateTo(.settings)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
    
    private func navigateTo(_ section: SidebarSection) {
        NotificationCenter.default.post(name: .navigateToSection, object: section)
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
