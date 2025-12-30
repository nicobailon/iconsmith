import SwiftUI
import AppKit

@MainActor
final class AppState: ObservableObject {
    @Published var iconLibrary: IconLibrary
    @Published var folders: [ScanFolder] = []
    @Published var presets: [Preset] = []
    @Published var recentActivity: [ActivityEntry] = []
    @Published var isLoading = false
    @Published var searchText = ""
    
    @Published var pendingFiles: [URL] = []
    @Published var showIconPicker = false
    
    @Published var currentOperation: OperationProgress?
    
    let iconService = IconService()
    lazy var folderScanService = FolderScanService(iconService: iconService)
    let geminiService = GeminiService()
    let undoManager = IconUndoManager()
    
    private let dataDirectory: URL
    
    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.dataDirectory = appSupport.appendingPathComponent("IconSmith", isDirectory: true)
        self.iconLibrary = IconLibrary(dataDirectory: dataDirectory)
        
        createDirectoryStructure()
        loadPersistedState()
    }
    
    private func createDirectoryStructure() {
        let directories = [
            dataDirectory,
            dataDirectory.appendingPathComponent("Icons/bundled", isDirectory: true),
            dataDirectory.appendingPathComponent("Icons/imported", isDirectory: true),
            dataDirectory.appendingPathComponent("Icons/generated", isDirectory: true),
            dataDirectory.appendingPathComponent("Icons/clipboard", isDirectory: true),
            dataDirectory.appendingPathComponent("undo", isDirectory: true)
        ]
        
        for dir in directories {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }
    
    private func loadPersistedState() {
        loadFolders()
        loadPresets()
        loadActivity()
        iconLibrary.load()
    }
    
    func saveState() {
        saveFolders()
        savePresets()
        saveActivity()
        iconLibrary.save()
    }
    
    private var foldersFileURL: URL {
        dataDirectory.appendingPathComponent("folders.json")
    }
    
    private var presetsFileURL: URL {
        dataDirectory.appendingPathComponent("presets.json")
    }
    
    private var activityFileURL: URL {
        dataDirectory.appendingPathComponent("activity.json")
    }
    
    private func loadFolders() {
        guard let data = try? Data(contentsOf: foldersFileURL),
              let decoded = try? JSONDecoder().decode([ScanFolder].self, from: data) else { return }
        folders = decoded
    }
    
    private func saveFolders() {
        guard let data = try? JSONEncoder().encode(folders) else { return }
        try? data.write(to: foldersFileURL)
    }
    
    private func loadPresets() {
        guard let data = try? Data(contentsOf: presetsFileURL),
              let decoded = try? JSONDecoder().decode([Preset].self, from: data) else { return }
        presets = decoded
    }
    
    private func savePresets() {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        try? data.write(to: presetsFileURL)
    }
    
    private func loadActivity() {
        guard let data = try? Data(contentsOf: activityFileURL),
              let decoded = try? JSONDecoder().decode([ActivityEntry].self, from: data) else { return }
        recentActivity = decoded
    }
    
    private func saveActivity() {
        let trimmed = Array(recentActivity.prefix(50))
        guard let data = try? JSONEncoder().encode(trimmed) else { return }
        try? data.write(to: activityFileURL)
    }
    
    func addFolder(_ url: URL) {
        guard url.hasDirectoryPath else { return }
        let folder = ScanFolder(id: UUID(), path: url, dateAdded: Date())
        folders.append(folder)
        saveFolders()
    }
    
    func removeFolder(_ id: UUID) {
        folders.removeAll { $0.id == id }
        saveFolders()
    }
    
    func logActivity(_ entry: ActivityEntry) {
        recentActivity.insert(entry, at: 0)
        if recentActivity.count > 50 {
            recentActivity = Array(recentActivity.prefix(50))
        }
        saveActivity()
    }
    
    func detectInconsistencies(in files: [FileTypeInfo]) -> [InconsistencyInfo] {
        var results: [InconsistencyInfo] = []
        
        let grouped = Dictionary(grouping: files) { $0.fileExtension }
        
        for (ext, extFiles) in grouped {
            let iconGroups = Dictionary(grouping: extFiles) {
                $0.currentIcon?.tiffRepresentation?.hashValue ?? 0
            }
            
            if iconGroups.count > 1 {
                let sorted = iconGroups.sorted { $0.value.count > $1.value.count }
                let dominant = sorted.first
                let outliers = sorted.dropFirst().flatMap { $0.value }
                
                results.append(InconsistencyInfo(
                    fileExtension: ext,
                    totalFiles: extFiles.count,
                    differentIconCount: iconGroups.count,
                    dominantIcon: dominant?.value.first?.currentIcon,
                    outlierFiles: outliers
                ))
            }
        }
        
        return results
    }
}

struct OperationProgress {
    let operation: String
    var current: Int
    var total: Int
    var isCancelled: Bool = false
}

struct InconsistencyInfo {
    let fileExtension: String
    let totalFiles: Int
    let differentIconCount: Int
    let dominantIcon: NSImage?
    let outlierFiles: [FileTypeInfo]
}
