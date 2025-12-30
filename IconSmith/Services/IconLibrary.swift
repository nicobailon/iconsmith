import Foundation
import AppKit

@MainActor
final class IconLibrary: ObservableObject {
    @Published var icons: [IconFile] = []
    
    private let dataDirectory: URL
    private var libraryFileURL: URL {
        dataDirectory.appendingPathComponent("library.json")
    }
    
    init(dataDirectory: URL) {
        self.dataDirectory = dataDirectory
    }
    
    func icon(for id: UUID) -> IconFile? {
        icons.first { $0.id == id }
    }
    
    func icons(in category: IconFile.IconCategory) -> [IconFile] {
        icons.filter { $0.category == category }
    }
    
    func icons(matching search: String) -> [IconFile] {
        guard !search.isEmpty else { return icons }
        return icons.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }
    
    func addIcon(_ icon: IconFile) {
        icons.append(icon)
        save()
    }
    
    func removeIcon(_ id: UUID) {
        guard let icon = icon(for: id) else { return }
        try? FileManager.default.removeItem(at: icon.path)
        icons.removeAll { $0.id == id }
        save()
    }
    
    func updateIcon(_ id: UUID, update: (inout IconFile) -> Void) {
        guard let index = icons.firstIndex(where: { $0.id == id }) else { return }
        update(&icons[index])
        save()
    }
    
    func incrementUsage(for id: UUID) {
        updateIcon(id) { icon in
            icon.usageCount += 1
        }
    }
    
    func importIcon(from sourceURL: URL, name: String, category: IconFile.IconCategory) throws -> IconFile {
        let id = UUID()
        let filename = "\(id.uuidString).\(sourceURL.pathExtension)"
        let destinationDir = dataDirectory.appendingPathComponent("Icons/imported", isDirectory: true)
        let destinationURL = destinationDir.appendingPathComponent(filename)
        
        try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        
        let icon = IconFile(
            id: id,
            name: name,
            path: destinationURL,
            category: category,
            source: .imported,
            dateAdded: Date(),
            usageCount: 0,
            associatedExtensions: []
        )
        
        addIcon(icon)
        return icon
    }
    
    func importFromClipboard(name: String, category: IconFile.IconCategory) throws -> IconFile? {
        guard let image = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage else {
            return nil
        }
        
        let id = UUID()
        let filename = "\(id.uuidString).png"
        let destinationDir = dataDirectory.appendingPathComponent("Icons/clipboard", isDirectory: true)
        let destinationURL = destinationDir.appendingPathComponent(filename)
        
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
        try pngData.write(to: destinationURL)
        
        let icon = IconFile(
            id: id,
            name: name,
            path: destinationURL,
            category: category,
            source: .clipboard,
            dateAdded: Date(),
            usageCount: 0,
            associatedExtensions: []
        )
        
        addIcon(icon)
        return icon
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(icons) else { return }
        try? data.write(to: libraryFileURL)
    }
    
    func load() {
        guard let data = try? Data(contentsOf: libraryFileURL),
              let decoded = try? JSONDecoder().decode([IconFile].self, from: data) else { return }
        icons = decoded
    }
}
