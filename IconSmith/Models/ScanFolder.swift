import Foundation

struct ScanFolder: Identifiable, Codable, Hashable {
    let id: UUID
    var path: URL
    var dateAdded: Date
    var lastScanned: Date?
    var fileCount: Int?
    
    var displayName: String {
        path.lastPathComponent
    }
    
    var displayPath: String {
        path.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ScanFolder, rhs: ScanFolder) -> Bool {
        lhs.id == rhs.id
    }
}
