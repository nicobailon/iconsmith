import SwiftUI
import UniformTypeIdentifiers

struct IconLibraryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: IconFile.IconCategory?
    @State private var selectedIcon: IconFile?
    @State private var iconSize: CGFloat = 64
    @State private var searchText = ""
    @State private var showImportSheet = false
    
    var filteredIcons: [IconFile] {
        var icons = appState.iconLibrary.icons
        if let category = selectedCategory {
            icons = icons.filter { $0.category == category }
        }
        if !searchText.isEmpty {
            icons = icons.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return icons.sorted { $0.usageCount > $1.usageCount }
    }
    
    var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: iconSize + 24))]
    }
    
    var body: some View {
        HSplitView {
            categorySidebar
                .frame(width: 180)
            
            VStack(spacing: 0) {
                toolbar
                Divider()
                iconGrid
                Divider()
                dropZone
            }
        }
        .navigationTitle("Icon Library")
        .sheet(isPresented: $showImportSheet) {
            ImportIconSheet()
        }
        .sheet(item: $selectedIcon) { icon in
            IconDetailSheet(icon: icon)
        }
    }
    
    private var categorySidebar: some View {
        List(selection: $selectedCategory) {
            Section("Categories") {
                Text("All")
                    .tag(nil as IconFile.IconCategory?)
                
                ForEach(IconFile.IconCategory.allCases, id: \.self) { category in
                    Label(category.displayName, systemImage: category.systemImage)
                        .tag(category as IconFile.IconCategory?)
                }
            }
        }
    }
    
    private var toolbar: some View {
        HStack {
            TextField("Search icons", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
            
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: "square.grid.4x3.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $iconSize, in: 32...256)
                    .frame(width: 100)
                Image(systemName: "square.grid.2x2.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Button("Import...") {
                showImportSheet = true
            }
            
            Button {
                importFromClipboard()
            } label: {
                Image(systemName: "doc.on.clipboard")
            }
            .help("Import from clipboard")
        }
        .padding()
    }
    
    private var iconGrid: some View {
        ScrollView {
            if filteredIcons.isEmpty {
                ContentUnavailableView(
                    "No Icons",
                    systemImage: "photo.on.rectangle",
                    description: Text("Import icons or generate with AI")
                )
                .padding(.top, 60)
            } else {
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(filteredIcons) { icon in
                        IconGridItem(
                            icon: icon,
                            size: iconSize,
                            isSelected: selectedIcon?.id == icon.id
                        )
                        .onTapGesture {
                            selectedIcon = icon
                        }
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                appState.iconLibrary.removeIcon(icon.id)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var dropZone: some View {
        DropZoneView(text: "Drop icons here to import") { urls in
            for url in urls {
                importIcon(from: url)
            }
        }
        .frame(height: 50)
    }
    
    private func importIcon(from url: URL) {
        let name = url.deletingPathExtension().lastPathComponent
        _ = try? appState.iconLibrary.importIcon(from: url, name: name, category: .custom)
    }
    
    private func importFromClipboard() {
        _ = try? appState.iconLibrary.importFromClipboard(name: "Clipboard \(Date().formatted(.dateTime.hour().minute()))", category: .custom)
    }
}

struct IconGridItem: View {
    let icon: IconFile
    let size: CGFloat
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            if let image = icon.image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
                    .frame(width: size, height: size)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
            
            if size >= 48 {
                Text(icon.name)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(width: size + 16)
            }
        }
        .padding(8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
