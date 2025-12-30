import SwiftUI

struct FolderBrowserView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFolder: ScanFolder?
    @State private var scannedFiles: [FileTypeInfo] = []
    @State private var isScanning = false
    
    var body: some View {
        HSplitView {
            folderList
                .frame(minWidth: 250, maxWidth: 300)
            
            if let folder = selectedFolder {
                FolderContentsView(
                    folder: folder,
                    scannedFiles: scannedFiles,
                    isScanning: isScanning
                )
            } else {
                ContentUnavailableView(
                    "Select a Folder",
                    systemImage: "folder",
                    description: Text("Choose a folder from the sidebar or add a new one")
                )
            }
        }
        .navigationTitle("Folders")
        .onChange(of: selectedFolder) { _, newFolder in
            if let folder = newFolder {
                Task { await scanFolder(folder) }
            }
        }
    }
    
    private var folderList: some View {
        VStack(spacing: 0) {
            List(appState.folders, selection: $selectedFolder) { folder in
                FolderRow(folder: folder)
                    .tag(folder)
                    .contextMenu {
                        Button("Remove", role: .destructive) {
                            appState.removeFolder(folder.id)
                        }
                    }
            }
            
            Divider()
            
            DropZoneView(text: "Drop folder here") { urls in
                for url in urls where url.hasDirectoryPath {
                    appState.addFolder(url)
                }
            }
            .frame(height: 60)
            
            HStack {
                Button("Add Folder...") {
                    showFolderPicker()
                }
                Spacer()
            }
            .padding()
        }
    }
    
    private func showFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        
        if panel.runModal() == .OK {
            for url in panel.urls {
                appState.addFolder(url)
            }
        }
    }
    
    private func scanFolder(_ folder: ScanFolder) async {
        isScanning = true
        scannedFiles = await appState.folderScanService.scanFolder(folder.path) { _ in }
        isScanning = false
    }
}

struct FolderRow: View {
    let folder: ScanFolder
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(folder.displayName)
                .font(.body)
            Text(folder.displayPath)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}

struct DropZoneView: View {
    let text: String
    let onDrop: ([URL]) -> Void
    
    @State private var isTargeted = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                .foregroundStyle(isTargeted ? .tint : .secondary)
            
            Text(text)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        Task { @MainActor in
                            onDrop([url])
                        }
                    }
                }
            }
            return true
        }
    }
}
