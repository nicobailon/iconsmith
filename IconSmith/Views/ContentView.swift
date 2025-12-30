import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedSection: SidebarSection = .dashboard
    
    enum SidebarSection: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case folders = "Folders"
        case library = "Icon Library"
        case presets = "Presets"
        case generate = "Generate"
        case settings = "Settings"
        
        var id: String { rawValue }
        
        var systemImage: String {
            switch self {
            case .dashboard: return "square.grid.2x2"
            case .folders: return "folder"
            case .library: return "photo.on.rectangle"
            case .presets: return "doc.badge.gearshape"
            case .generate: return "wand.and.stars"
            case .settings: return "gearshape"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(SidebarSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            detailView
        }
        .frame(minWidth: 900, minHeight: 600)
        .sheet(isPresented: $appState.showIconPicker) {
            ApplySheet(files: appState.pendingFiles)
        }
        .overlay(alignment: .bottom) {
            if let progress = appState.currentOperation {
                ProgressBarView(
                    operation: progress.operation,
                    current: progress.current,
                    total: progress.total,
                    onCancel: {
                        appState.currentOperation?.isCancelled = true
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    private var detailView: some View {
        switch selectedSection {
        case .dashboard:
            DashboardView()
        case .folders:
            FolderBrowserView()
        case .library:
            IconLibraryView()
        case .presets:
            PresetListView()
        case .generate:
            AIGeneratorView()
        case .settings:
            SettingsView()
        }
    }
}
