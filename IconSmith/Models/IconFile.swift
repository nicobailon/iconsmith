import Foundation
import AppKit

struct IconFile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var path: URL
    var category: IconCategory
    var source: IconSource
    var dateAdded: Date
    var usageCount: Int
    var associatedExtensions: [String]
    
    enum IconCategory: String, Codable, CaseIterable {
        case code
        case design
        case system
        case custom
        
        var displayName: String {
            rawValue.capitalized
        }
        
        var systemImage: String {
            switch self {
            case .code: return "curlybraces"
            case .design: return "paintbrush"
            case .system: return "gearshape"
            case .custom: return "star"
            }
        }
    }
    
    enum IconSource: String, Codable {
        case bundled
        case imported
        case aiGenerated
        case clipboard
    }
    
    var image: NSImage? {
        NSImage(contentsOf: path)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: IconFile, rhs: IconFile) -> Bool {
        lhs.id == rhs.id
    }
}
