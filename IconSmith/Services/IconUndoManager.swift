import Foundation
import AppKit

@MainActor
final class IconUndoManager: ObservableObject {
    @Published private(set) var canUndo: Bool = false
    
    private var undoStack: [UndoEntry] = []
    private let maxEntries = 50
    private let undoDirectory: URL
    
    struct UndoEntry: Codable {
        let id: UUID
        let timestamp: Date
        let filePath: String
        let hadCustomIcon: Bool
        let originalIconPath: String?
    }
    
    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.undoDirectory = appSupport.appendingPathComponent("IconSmith/undo", isDirectory: true)
        try? FileManager.default.createDirectory(at: undoDirectory, withIntermediateDirectories: true)
        load()
    }
    
    func saveOriginalIcon(for fileURL: URL) {
        let entry: UndoEntry
        
        if hasCustomIcon(fileURL) {
            let originalIcon = NSWorkspace.shared.icon(forFile: fileURL.path)
            let id = UUID()
            let iconPath = undoDirectory.appendingPathComponent("\(id.uuidString).png")
            
            if let pngData = ICNSConverter.pngData(from: originalIcon) {
                try? pngData.write(to: iconPath)
                entry = UndoEntry(
                    id: id,
                    timestamp: Date(),
                    filePath: fileURL.path,
                    hadCustomIcon: true,
                    originalIconPath: iconPath.path
                )
            } else {
                entry = UndoEntry(
                    id: id,
                    timestamp: Date(),
                    filePath: fileURL.path,
                    hadCustomIcon: true,
                    originalIconPath: nil
                )
            }
        } else {
            entry = UndoEntry(
                id: UUID(),
                timestamp: Date(),
                filePath: fileURL.path,
                hadCustomIcon: false,
                originalIconPath: nil
            )
        }
        
        undoStack.insert(entry, at: 0)
        trimStack()
        save()
        canUndo = !undoStack.isEmpty
    }
    
    func undo() -> Bool {
        guard let entry = undoStack.first else { return false }
        
        let fileURL = URL(fileURLWithPath: entry.filePath)
        
        if entry.hadCustomIcon, let iconPath = entry.originalIconPath {
            let iconURL = URL(fileURLWithPath: iconPath)
            if let icon = NSImage(contentsOf: iconURL) {
                NSWorkspace.shared.setIcon(icon, forFile: fileURL.path, options: [])
            }
        } else {
            NSWorkspace.shared.setIcon(nil, forFile: fileURL.path, options: [])
        }
        
        if let iconPath = entry.originalIconPath {
            try? FileManager.default.removeItem(atPath: iconPath)
        }
        
        undoStack.removeFirst()
        save()
        canUndo = !undoStack.isEmpty
        
        return true
    }
    
    func clearHistory() {
        for entry in undoStack {
            if let iconPath = entry.originalIconPath {
                try? FileManager.default.removeItem(atPath: iconPath)
            }
        }
        undoStack.removeAll()
        save()
        canUndo = false
    }
    
    private func hasCustomIcon(_ fileURL: URL) -> Bool {
        let resourceForkPath = fileURL.path + "/..namedfork/rsrc"
        guard FileManager.default.fileExists(atPath: resourceForkPath) else {
            return false
        }
        let size = (try? FileManager.default.attributesOfItem(atPath: resourceForkPath)[.size] as? Int) ?? 0
        return size > 0
    }
    
    private func trimStack() {
        while undoStack.count > maxEntries {
            if let removed = undoStack.popLast(), let iconPath = removed.originalIconPath {
                try? FileManager.default.removeItem(atPath: iconPath)
            }
        }
    }
    
    private var stackFileURL: URL {
        undoDirectory.appendingPathComponent("stack.json")
    }
    
    private func save() {
        guard let data = try? JSONEncoder().encode(undoStack) else { return }
        try? data.write(to: stackFileURL)
    }
    
    private func load() {
        guard let data = try? Data(contentsOf: stackFileURL),
              let decoded = try? JSONDecoder().decode([UndoEntry].self, from: data) else { return }
        undoStack = decoded
        canUndo = !undoStack.isEmpty
    }
}
