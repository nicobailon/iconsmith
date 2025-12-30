import Foundation

struct ActivityEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let action: ActionType
    let filePaths: [String]
    let iconUsed: UUID?
    let previousIconData: Data?
    
    enum ActionType: String, Codable {
        case applied
        case removed
        case batchApplied
        case generated
        
        var displayName: String {
            switch self {
            case .applied: return "Applied"
            case .removed: return "Removed"
            case .batchApplied: return "Batch Applied"
            case .generated: return "Generated"
            }
        }
        
        var systemImage: String {
            switch self {
            case .applied: return "checkmark.circle"
            case .removed: return "xmark.circle"
            case .batchApplied: return "checkmark.circle.fill"
            case .generated: return "wand.and.stars"
            }
        }
    }
    
    init(
        id: UUID = UUID(),
        action: ActionType,
        filePaths: [String],
        iconUsed: UUID? = nil,
        previousIconData: Data? = nil
    ) {
        self.id = id
        self.timestamp = Date()
        self.action = action
        self.filePaths = filePaths
        self.iconUsed = iconUsed
        self.previousIconData = previousIconData
    }
    
    var fileCount: Int {
        filePaths.count
    }
    
    var summary: String {
        if filePaths.count == 1 {
            let filename = URL(fileURLWithPath: filePaths[0]).lastPathComponent
            return "\(action.displayName) icon for \(filename)"
        } else {
            return "\(action.displayName) icon for \(filePaths.count) files"
        }
    }
}
