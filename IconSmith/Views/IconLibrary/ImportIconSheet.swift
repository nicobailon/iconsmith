import SwiftUI
import UniformTypeIdentifiers

struct ImportIconSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var selectedURL: URL?
    @State private var name = ""
    @State private var category: IconFile.IconCategory = .custom
    @State private var previewImage: NSImage?
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Import Icon")
                .font(.title2.bold())
            
            HStack(spacing: 24) {
                previewArea
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name")
                            .font(.headline)
                        TextField("Icon name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Category")
                            .font(.headline)
                        Picker("Category", selection: $category) {
                            ForEach(IconFile.IconCategory.allCases, id: \.self) { cat in
                                Text(cat.displayName).tag(cat)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .frame(width: 250)
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Import") {
                    importIcon()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(selectedURL == nil || name.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 500)
    }
    
    private var previewArea: some View {
        VStack {
            if let image = previewImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 128, height: 128)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .foregroundStyle(.secondary)
                    .frame(width: 128, height: 128)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.largeTitle)
                            Text("Select File")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
            }
            
            Button("Choose File...") {
                chooseFile()
            }
        }
        .frame(width: 150)
    }
    
    private func chooseFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .icns, UTType(filenameExtension: "svg")].compactMap { $0 }
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            selectedURL = url
            name = url.deletingPathExtension().lastPathComponent
            previewImage = NSImage(contentsOf: url)
        }
    }
    
    private func importIcon() {
        guard let url = selectedURL else { return }
        
        do {
            _ = try appState.iconLibrary.importIcon(from: url, name: name, category: category)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct IconDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    let icon: IconFile
    
    @State private var editedName: String
    @State private var editedCategory: IconFile.IconCategory
    
    init(icon: IconFile) {
        self.icon = icon
        _editedName = State(initialValue: icon.name)
        _editedCategory = State(initialValue: icon.category)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = icon.image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 128, height: 128)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name")
                        .font(.headline)
                    TextField("Icon name", text: $editedName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Category")
                        .font(.headline)
                    Picker("Category", selection: $editedCategory) {
                        ForEach(IconFile.IconCategory.allCases, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                HStack {
                    Text("Used \(icon.usageCount) times")
                    Spacer()
                    Text("Added \(icon.dateAdded.formatted(date: .abbreviated, time: .omitted))")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            HStack {
                Button("Delete", role: .destructive) {
                    appState.iconLibrary.removeIcon(icon.id)
                    dismiss()
                }
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Save") {
                    appState.iconLibrary.updateIcon(icon.id) { icon in
                        icon.name = editedName
                        icon.category = editedCategory
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 350)
    }
}
