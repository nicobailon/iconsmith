import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAPIKeySetup = false
    @State private var showClearConfirmation = false
    
    var body: some View {
        Form {
            Section("Gemini AI") {
                HStack {
                    Label(
                        appState.geminiService.hasAPIKey ? "API Key Configured" : "No API Key",
                        systemImage: appState.geminiService.hasAPIKey ? "checkmark.circle.fill" : "xmark.circle"
                    )
                    .foregroundStyle(appState.geminiService.hasAPIKey ? .green : .secondary)
                    
                    Spacer()
                    
                    Button(appState.geminiService.hasAPIKey ? "Change" : "Setup") {
                        showAPIKeySetup = true
                    }
                }
            }
            
            Section("Undo History") {
                HStack {
                    Text("Undo entries available")
                    Spacer()
                    Text(appState.undoManager.canUndo ? "Yes" : "No")
                        .foregroundStyle(.secondary)
                }
                
                Button("Clear Undo History", role: .destructive) {
                    showClearConfirmation = true
                }
            }
            
            Section("Data") {
                HStack {
                    Text("Icons in library")
                    Spacer()
                    Text("\(appState.iconLibrary.icons.count)")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Configured folders")
                    Spacer()
                    Text("\(appState.folders.count)")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Presets")
                    Spacer()
                    Text("\(appState.presets.count)")
                        .foregroundStyle(.secondary)
                }
                
                Button("Reveal Data in Finder") {
                    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                    let iconsmithDir = appSupport.appendingPathComponent("IconSmith")
                    NSWorkspace.shared.open(iconsmithDir)
                }
            }
            
            Section("Finder Extension") {
                HStack {
                    Text("Enable in System Settings")
                    Spacer()
                    Button("Open Settings") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences")!)
                    }
                }
                
                Text("The Finder extension must be enabled in System Settings > Extensions > Finder Extensions for the right-click menu to appear.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                
                Link("View on GitHub", destination: URL(string: "https://github.com/nicobailon/iconsmith")!)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .sheet(isPresented: $showAPIKeySetup) {
            APIKeySetupSheet()
        }
        .confirmationDialog(
            "Clear Undo History?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear", role: .destructive) {
                appState.undoManager.clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all undo history. You will not be able to revert previous icon changes.")
        }
    }
}
