import Foundation

struct Preset: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var mappings: [String: UUID]
    var dateCreated: Date
    var dateModified: Date
    
    init(id: UUID = UUID(), name: String, mappings: [String: UUID] = [:]) {
        self.id = id
        self.name = name
        self.mappings = mappings
        self.dateCreated = Date()
        self.dateModified = Date()
    }
    
    mutating func setMapping(extension ext: String, iconID: UUID) {
        let normalized = ext.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        mappings[normalized] = iconID
        dateModified = Date()
    }
    
    mutating func removeMapping(extension ext: String) {
        let normalized = ext.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        mappings.removeValue(forKey: normalized)
        dateModified = Date()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Preset, rhs: Preset) -> Bool {
        lhs.id == rhs.id
    }
}
