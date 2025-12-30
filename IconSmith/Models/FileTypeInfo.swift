import Foundation
import AppKit

struct FileTypeInfo: Identifiable {
    var id: String { path }
    let path: String
    let filename: String
    let fileExtension: String
    let currentIcon: NSImage?
    let hasCustomIcon: Bool
    let isIconSmithApplied: Bool
    
    var url: URL {
        URL(fileURLWithPath: path)
    }
}
