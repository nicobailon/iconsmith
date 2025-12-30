import SwiftUI

struct ApplySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    let files: [URL]
    
    @State private var groupedSelection: [String: UUID] = [:]
    @State private var isApplying = false
    @State private var showPreview = false
    
    var groupedFiles: [String: [URL]] {
        Dictionary(grouping: files) { $0.pathExtension.lowercased() }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            groupList
            Divider()
            footer
        }
        .frame(width: 500, height: 450)
        .sheet(isPresented: $showPreview) {
            PreviewSheet(files: files, iconMapping: groupedSelection)
        }
    }
    
    private var header: some View {
        HStack {
            Text("Apply Icons to \(files.count) Files")
                .font(.title2.bold())
            Spacer()
        }
        .padding()
    }
    
    private var groupList: some View {
        List {
            ForEach(groupedFiles.keys.sorted(), id: \.self) { ext in
                ExtensionGroupRow(
                    fileExtension: ext,
                    fileCount: groupedFiles[ext]?.count ?? 0,
                    selectedIconID: groupedSelection[ext],
                    onSelectIcon: { iconID in
                        groupedSelection[ext] = iconID
                    }
                )
            }
        }
    }
    
    private var footer: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            
            Spacer()
            
            Button("Preview Changes") {
                showPreview = true
            }
            .disabled(groupedSelection.isEmpty)
            
            Button {
                applyIcons()
            } label: {
                if isApplying {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Apply")
                }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(groupedSelection.isEmpty || isApplying)
        }
        .padding()
    }
    
    private func applyIcons() {
        isApplying = true
        
        Task {
            for (ext, iconID) in groupedSelection {
                guard let icon = appState.iconLibrary.icon(for: iconID),
                      let image = icon.image else { continue }
                
                let filesToApply = groupedFiles[ext] ?? []
                for file in filesToApply {
                    appState.undoManager.saveOriginalIcon(for: file)
                    try? appState.iconService.applyIcon(image, to: file)
                }
                
                appState.iconLibrary.incrementUsage(for: iconID)
                
                appState.logActivity(ActivityEntry(
                    action: filesToApply.count > 1 ? .batchApplied : .applied,
                    filePaths: filesToApply.map { $0.path },
                    iconUsed: iconID
                ))
            }
            
            isApplying = false
            dismiss()
        }
    }
}

struct ExtensionGroupRow: View {
    @EnvironmentObject var appState: AppState
    @State private var showIconPicker = false
    
    let fileExtension: String
    let fileCount: Int
    let selectedIconID: UUID?
    let onSelectIcon: (UUID) -> Void
    
    var selectedIcon: IconFile? {
        guard let id = selectedIconID else { return nil }
        return appState.iconLibrary.icon(for: id)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(".\(fileExtension)")
                    .font(.headline.monospaced())
                Text("\(fileCount) files")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let icon = selectedIcon, let image = icon.image {
                Image(nsImage: image)
                    .resizable()
                    .frame(width: 32, height: 32)
                Text(icon.name)
                    .font(.subheadline)
            }
            
            Button(selectedIconID == nil ? "Select Icon" : "Change") {
                showIconPicker = true
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showIconPicker) {
            IconSelectionSheet { iconID in
                onSelectIcon(iconID)
            }
        }
    }
}

struct PreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    let files: [URL]
    let iconMapping: [String: UUID]
    
    var previewItems: [(URL, IconFile?)] {
        files.prefix(20).map { file in
            let ext = file.pathExtension.lowercased()
            let iconID = iconMapping[ext]
            let icon = iconID.flatMap { appState.iconLibrary.icon(for: $0) }
            return (file, icon)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Preview Changes")
                    .font(.title2.bold())
                Spacer()
                Button("Close") { dismiss() }
            }
            .padding()
            
            Divider()
            
            List {
                ForEach(previewItems, id: \.0) { file, icon in
                    HStack {
                        if let icon = icon, let image = icon.image {
                            Image(nsImage: image)
                                .resizable()
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "doc")
                                .frame(width: 24, height: 24)
                        }
                        
                        Text(file.lastPathComponent)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if icon != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            
            if files.count > 20 {
                Text("Showing first 20 of \(files.count) files")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .frame(width: 400, height: 400)
    }
}
