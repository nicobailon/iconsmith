import Cocoa
import FinderSync

class FinderSync: FIFinderSync {
    
    private let sharedContainerID = "group.com.nicobailon.IconSmith"
    
    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "IconSmith")
        
        let setIconItem = NSMenuItem(
            title: "Set Icon with IconSmith",
            action: #selector(setIconAction(_:)),
            keyEquivalent: ""
        )
        setIconItem.image = NSImage(systemSymbolName: "photo.badge.plus", accessibilityDescription: nil)
        menu.addItem(setIconItem)
        
        let removeIconItem = NSMenuItem(
            title: "Remove Custom Icon",
            action: #selector(removeIconAction(_:)),
            keyEquivalent: ""
        )
        removeIconItem.image = NSImage(systemSymbolName: "photo.badge.minus", accessibilityDescription: nil)
        menu.addItem(removeIconItem)
        
        let recentIcons = loadRecentIcons()
        if !recentIcons.isEmpty {
            menu.addItem(NSMenuItem.separator())
            
            let recentMenu = NSMenu(title: "Recent Icons")
            for icon in recentIcons.prefix(5) {
                let item = NSMenuItem(
                    title: icon.name,
                    action: #selector(applyRecentIcon(_:)),
                    keyEquivalent: ""
                )
                item.representedObject = icon.id.uuidString
                if let thumbnailPath = icon.thumbnailPath,
                   let thumbnail = NSImage(contentsOfFile: thumbnailPath) {
                    item.image = thumbnail
                    item.image?.size = NSSize(width: 16, height: 16)
                }
                recentMenu.addItem(item)
            }
            
            let recentItem = NSMenuItem(title: "Apply Recent Icon", action: nil, keyEquivalent: "")
            recentItem.submenu = recentMenu
            menu.addItem(recentItem)
        }
        
        return menu
    }
    
    @objc func setIconAction(_ sender: AnyObject?) {
        guard let items = FIFinderSyncController.default().selectedItemURLs() else { return }
        
        let encodedURLs = items
            .map { $0.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "" }
            .joined(separator: ",")
        
        if let appURL = URL(string: "iconsmith://apply?files=\(encodedURLs)") {
            NSWorkspace.shared.open(appURL)
        }
    }
    
    @objc func removeIconAction(_ sender: AnyObject?) {
        guard let items = FIFinderSyncController.default().selectedItemURLs() else { return }
        
        for url in items {
            NSWorkspace.shared.setIcon(nil, forFile: url.path, options: [])
            removeIconSmithMarker(from: url)
        }
    }
    
    @objc func applyRecentIcon(_ sender: NSMenuItem) {
        guard let iconIDString = sender.representedObject as? String,
              let iconID = UUID(uuidString: iconIDString),
              let items = FIFinderSyncController.default().selectedItemURLs() else { return }
        
        applyIcon(id: iconID, to: items)
    }
    
    private func loadRecentIcons() -> [RecentIcon] {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: sharedContainerID) else {
            return []
        }
        
        let recentFile = containerURL.appendingPathComponent("recent-icons.json")
        guard let data = try? Data(contentsOf: recentFile),
              let recent = try? JSONDecoder().decode([RecentIcon].self, from: data) else {
            return []
        }
        
        return recent
    }
    
    private func applyIcon(id: UUID, to files: [URL]) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: sharedContainerID) else {
            return
        }
        
        let iconPath = containerURL.appendingPathComponent("Icons/\(id.uuidString).png")
        guard let icon = NSImage(contentsOf: iconPath) else { return }
        
        for file in files {
            NSWorkspace.shared.setIcon(icon, forFile: file.path, options: [])
            setIconSmithMarker(for: file)
        }
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

struct RecentIcon: Codable {
    let id: UUID
    let name: String
    let thumbnailPath: String?
}
