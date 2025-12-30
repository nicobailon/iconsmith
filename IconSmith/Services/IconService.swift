import Foundation
import AppKit

@MainActor
final class IconService {
    
    enum IconError: LocalizedError {
        case failedToApply(URL)
        case failedToRemove(URL)
        case fileNotFound(URL)
        
        var errorDescription: String? {
            switch self {
            case .failedToApply(let url):
                return "Failed to apply icon to \(url.lastPathComponent)"
            case .failedToRemove(let url):
                return "Failed to remove icon from \(url.lastPathComponent)"
            case .fileNotFound(let url):
                return "File not found: \(url.lastPathComponent)"
            }
        }
    }
    
    struct BatchResult {
        let succeeded: [URL]
        let failed: [(URL, Error)]
        
        var successCount: Int { succeeded.count }
        var failureCount: Int { failed.count }
        var totalCount: Int { succeeded.count + failed.count }
    }
    
    func applyIcon(_ icon: NSImage, to fileURL: URL) throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw IconError.fileNotFound(fileURL)
        }
        
        let success = NSWorkspace.shared.setIcon(icon, forFile: fileURL.path, options: [])
        if !success {
            throw IconError.failedToApply(fileURL)
        }
        
        setIconSmithMarker(for: fileURL)
    }
    
    func removeIcon(from fileURL: URL) throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw IconError.fileNotFound(fileURL)
        }
        
        let success = NSWorkspace.shared.setIcon(nil, forFile: fileURL.path, options: [])
        if !success {
            throw IconError.failedToRemove(fileURL)
        }
        
        removeIconSmithMarker(from: fileURL)
    }
    
    func batchApply(
        icon: NSImage,
        to files: [URL],
        progress: @escaping (Int, Int) -> Void
    ) -> BatchResult {
        var succeeded: [URL] = []
        var failed: [(URL, Error)] = []
        
        for (index, file) in files.enumerated() {
            do {
                try applyIcon(icon, to: file)
                succeeded.append(file)
            } catch {
                failed.append((file, error))
            }
            progress(index + 1, files.count)
        }
        
        return BatchResult(succeeded: succeeded, failed: failed)
    }
    
    func batchRemove(
        from files: [URL],
        progress: @escaping (Int, Int) -> Void
    ) -> BatchResult {
        var succeeded: [URL] = []
        var failed: [(URL, Error)] = []
        
        for (index, file) in files.enumerated() {
            do {
                try removeIcon(from: file)
                succeeded.append(file)
            } catch {
                failed.append((file, error))
            }
            progress(index + 1, files.count)
        }
        
        return BatchResult(succeeded: succeeded, failed: failed)
    }
    
    func hasCustomIcon(_ fileURL: URL) -> Bool {
        let resourceForkPath = fileURL.path + "/..namedfork/rsrc"
        guard FileManager.default.fileExists(atPath: resourceForkPath) else {
            return false
        }
        let size = (try? FileManager.default.attributesOfItem(atPath: resourceForkPath)[.size] as? Int) ?? 0
        return size > 0
    }
    
    func hasIconSmithAppliedMarker(_ fileURL: URL) -> Bool {
        fileURL.withUnsafeFileSystemRepresentation { path -> Bool in
            guard let path = path else { return false }
            let length = getxattr(path, "com.iconsmith.applied", nil, 0, 0, 0)
            return length > 0
        }
    }
    
    func getCurrentIcon(for fileURL: URL) -> NSImage {
        NSWorkspace.shared.icon(forFile: fileURL.path)
    }
    
    private func setIconSmithMarker(for fileURL: URL) {
        let marker = "1"
        fileURL.withUnsafeFileSystemRepresentation { path in
            guard let path = path else { return }
            marker.withCString { ptr in
                _ = setxattr(path, "com.iconsmith.applied", ptr, marker.count, 0, 0)
            }
        }
    }
    
    private func removeIconSmithMarker(from fileURL: URL) {
        fileURL.withUnsafeFileSystemRepresentation { path in
            guard let path = path else { return }
            _ = removexattr(path, "com.iconsmith.applied", 0)
        }
    }
}
