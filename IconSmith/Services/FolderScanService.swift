import Foundation
import AppKit

@MainActor
final class FolderScanService {
    private let iconService: IconService
    
    init(iconService: IconService) {
        self.iconService = iconService
    }
    
    func scanFolder(
        _ folder: URL,
        extensions: Set<String>? = nil,
        progress: @escaping (Int) -> Void
    ) async -> [FileTypeInfo] {
        let iconServiceRef = iconService
        
        return await withCheckedContinuation { continuation in
            Task.detached {
                var results: [FileTypeInfo] = []
                let enumerator = FileManager.default.enumerator(
                    at: folder,
                    includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]
                )
                
                var count = 0
                while let url = enumerator?.nextObject() as? URL {
                    let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                    guard !isDirectory else { continue }
                    
                    let ext = url.pathExtension.lowercased()
                    if let filter = extensions, !filter.contains(ext) { continue }
                    
                    let (currentIcon, hasCustom, isIconSmith) = await MainActor.run {
                        (NSWorkspace.shared.icon(forFile: url.path),
                         iconServiceRef.hasCustomIcon(url),
                         iconServiceRef.hasIconSmithAppliedMarker(url))
                    }
                    
                    let info = FileTypeInfo(
                        path: url.path,
                        filename: url.lastPathComponent,
                        fileExtension: ext,
                        currentIcon: currentIcon,
                        hasCustomIcon: hasCustom,
                        isIconSmithApplied: isIconSmith
                    )
                    results.append(info)
                    count += 1
                    
                    await MainActor.run {
                        progress(count)
                    }
                }
                
                continuation.resume(returning: results)
            }
        }
    }
    
    func scanFolder(_ folder: URL) async -> [FileTypeInfo] {
        await scanFolder(folder, extensions: nil, progress: { _ in })
    }
}
