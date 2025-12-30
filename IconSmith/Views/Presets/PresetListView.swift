import SwiftUI

struct PresetListView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedPreset: Preset?
    @State private var showNewPresetSheet = false
    
    var body: some View {
        HSplitView {
            presetList
                .frame(minWidth: 200, maxWidth: 250)
            
            if let preset = selectedPreset {
                PresetEditorView(preset: binding(for: preset))
            } else {
                ContentUnavailableView(
                    "Select a Preset",
                    systemImage: "doc.badge.gearshape",
                    description: Text("Choose a preset from the sidebar or create a new one")
                )
            }
        }
        .navigationTitle("Presets")
        .sheet(isPresented: $showNewPresetSheet) {
            NewPresetSheet { preset in
                appState.presets.append(preset)
                appState.saveState()
                selectedPreset = preset
            }
        }
    }
    
    private var presetList: some View {
        VStack(spacing: 0) {
            List(appState.presets, selection: $selectedPreset) { preset in
                PresetRow(preset: preset)
                    .tag(preset)
                    .contextMenu {
                        Button("Duplicate") {
                            duplicatePreset(preset)
                        }
                        Button("Delete", role: .destructive) {
                            deletePreset(preset)
                        }
                    }
            }
            
            Divider()
            
            HStack {
                Button("New Preset") {
                    showNewPresetSheet = true
                }
                Spacer()
            }
            .padding()
        }
    }
    
    private func binding(for preset: Preset) -> Binding<Preset> {
        guard let index = appState.presets.firstIndex(where: { $0.id == preset.id }) else {
            return .constant(preset)
        }
        return Binding(
            get: { appState.presets[index] },
            set: { newValue in
                appState.presets[index] = newValue
                appState.saveState()
            }
        )
    }
    
    private func duplicatePreset(_ preset: Preset) {
        let newPreset = Preset(name: "\(preset.name) Copy", mappings: preset.mappings)
        appState.presets.append(newPreset)
        appState.saveState()
    }
    
    private func deletePreset(_ preset: Preset) {
        appState.presets.removeAll { $0.id == preset.id }
        if selectedPreset?.id == preset.id {
            selectedPreset = nil
        }
        appState.saveState()
    }
}

struct PresetRow: View {
    let preset: Preset
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(preset.name)
                .font(.body)
            Text("\(preset.mappings.count) mappings")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct NewPresetSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onCreate: (Preset) -> Void
    
    @State private var name = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New Preset")
                .font(.title2.bold())
            
            TextField("Preset name", text: $name)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Create") {
                    let preset = Preset(name: name)
                    onCreate(preset)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 300)
    }
}

struct PresetEditorView: View {
    @Binding var preset: Preset
    @EnvironmentObject var appState: AppState
    @State private var newExtension = ""
    @State private var showIconPicker = false
    @State private var editingExtension: String?
    @State private var showFolderPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            mappingList
        }
        .sheet(isPresented: $showIconPicker) {
            if let ext = editingExtension {
                IconSelectionSheet { iconID in
                    preset.setMapping(extension: ext, iconID: iconID)
                    editingExtension = nil
                }
            }
        }
    }
    
    private var header: some View {
        HStack {
            TextField("Preset Name", text: $preset.name)
                .font(.title2)
                .textFieldStyle(.plain)
            
            Spacer()
            
            Button("Apply to Folder...") {
                showFolderPicker = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .fileImporter(isPresented: $showFolderPicker, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result {
                applyPresetToFolder(url)
            }
        }
    }
    
    private var mappingList: some View {
        List {
            ForEach(Array(preset.mappings.keys.sorted()), id: \.self) { ext in
                MappingRow(
                    fileExtension: ext,
                    iconID: preset.mappings[ext],
                    onChangeIcon: {
                        editingExtension = ext
                        showIconPicker = true
                    },
                    onDelete: {
                        preset.removeMapping(extension: ext)
                    }
                )
            }
            
            HStack {
                TextField("Extension", text: $newExtension)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                
                Button("Add") {
                    guard !newExtension.isEmpty else { return }
                    editingExtension = newExtension
                    newExtension = ""
                    showIconPicker = true
                }
                .disabled(newExtension.isEmpty)
            }
            .padding(.vertical, 8)
        }
    }
    
    private func applyPresetToFolder(_ folderURL: URL) {
        Task {
            let files = await appState.folderScanService.scanFolder(folderURL)
            var allAppliedPaths: [String] = []
            
            for (ext, iconID) in preset.mappings {
                guard let icon = appState.iconLibrary.icon(for: iconID),
                      let image = icon.image else { continue }
                
                let matchingFiles = files.filter { $0.fileExtension == ext }
                for file in matchingFiles {
                    appState.undoManager.saveOriginalIcon(for: file.url)
                    try? appState.iconService.applyIcon(image, to: file.url)
                    allAppliedPaths.append(file.path)
                }
                
                appState.iconLibrary.incrementUsage(for: iconID)
            }
            
            if !allAppliedPaths.isEmpty {
                appState.logActivity(ActivityEntry(
                    action: .batchApplied,
                    filePaths: allAppliedPaths
                ))
            }
        }
    }
}

struct MappingRow: View {
    @EnvironmentObject var appState: AppState
    
    let fileExtension: String
    let iconID: UUID?
    let onChangeIcon: () -> Void
    let onDelete: () -> Void
    
    var icon: IconFile? {
        guard let id = iconID else { return nil }
        return appState.iconLibrary.icon(for: id)
    }
    
    var body: some View {
        HStack {
            Text(".\(fileExtension)")
                .font(.system(.body, design: .monospaced))
                .frame(width: 80, alignment: .leading)
            
            Image(systemName: "arrow.right")
                .foregroundStyle(.secondary)
            
            if let icon = icon, let image = icon.image {
                Image(nsImage: image)
                    .resizable()
                    .frame(width: 24, height: 24)
                Text(icon.name)
            } else {
                Text("Select icon...")
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Change") {
                onChangeIcon()
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
        }
        .padding(.vertical, 4)
    }
}

struct IconSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    let onSelect: (UUID) -> Void
    
    @State private var searchText = ""
    
    var filteredIcons: [IconFile] {
        if searchText.isEmpty {
            return appState.iconLibrary.icons
        }
        return appState.iconLibrary.icons.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Select Icon")
                    .font(.title2.bold())
                Spacer()
                Button("Cancel") { dismiss() }
            }
            .padding()
            
            TextField("Search", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                    ForEach(filteredIcons) { icon in
                        Button {
                            onSelect(icon.id)
                            dismiss()
                        } label: {
                            VStack {
                                if let image = icon.image {
                                    Image(nsImage: image)
                                        .resizable()
                                        .frame(width: 48, height: 48)
                                }
                                Text(icon.name)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .frame(width: 400, height: 400)
    }
}
