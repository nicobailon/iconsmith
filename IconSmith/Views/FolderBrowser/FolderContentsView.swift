import SwiftUI

struct FolderContentsView: View {
    @EnvironmentObject var appState: AppState
    
    let folder: ScanFolder
    let scannedFiles: [FileTypeInfo]
    let isScanning: Bool
    
    @State private var selectedFiles: Set<String> = []
    @State private var groupByExtension = true
    @State private var showIconPicker = false
    @State private var extensionFilter = ""
    
    var filteredFiles: [FileTypeInfo] {
        guard !extensionFilter.isEmpty else { return scannedFiles }
        return scannedFiles.filter { $0.fileExtension.localizedCaseInsensitiveContains(extensionFilter) }
    }
    
    var groupedFiles: [String: [FileTypeInfo]] {
        Dictionary(grouping: filteredFiles) { $0.fileExtension }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            
            if isScanning {
                ProgressView("Scanning...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if scannedFiles.isEmpty {
                ContentUnavailableView(
                    "No Files Found",
                    systemImage: "doc",
                    description: Text("This folder contains no files")
                )
            } else {
                fileList
            }
        }
    }
    
    private var toolbar: some View {
        HStack {
            TextField("Filter by extension", text: $extensionFilter)
                .textFieldStyle(.roundedBorder)
                .frame(width: 150)
            
            Toggle("Group by extension", isOn: $groupByExtension)
            
            Spacer()
            
            if !selectedFiles.isEmpty {
                Button("Apply Icon to \(selectedFiles.count) files...") {
                    showIconPicker = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            Text("\(filteredFiles.count) files")
                .foregroundStyle(.secondary)
        }
        .padding()
        .sheet(isPresented: $showIconPicker) {
            ApplySheet(files: Array(selectedFiles).map { URL(fileURLWithPath: $0) })
                .onDisappear {
                    selectedFiles.removeAll()
                }
        }
    }
    
    private var fileList: some View {
        List(selection: $selectedFiles) {
            if groupByExtension {
                ForEach(groupedFiles.keys.sorted(), id: \.self) { ext in
                    ExtensionGroupSection(
                        fileExtension: ext,
                        files: groupedFiles[ext] ?? []
                    )
                }
            } else {
                ForEach(filteredFiles) { file in
                    FileRow(file: file)
                        .tag(file.path)
                }
            }
        }
    }
}

struct ExtensionGroupSection: View {
    @EnvironmentObject var appState: AppState
    
    let fileExtension: String
    let files: [FileTypeInfo]
    
    @State private var isExpanded = true
    @State private var showFixSheet = false
    
    var customIconCount: Int {
        files.filter { $0.hasCustomIcon }.count
    }
    
    var inconsistencyInfo: InconsistencyInfo? {
        let inconsistencies = appState.detectInconsistencies(in: files)
        return inconsistencies.first
    }
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if let info = inconsistencyInfo {
                InconsistencyAlert(info: info) {
                    showFixSheet = true
                }
            }
            
            ForEach(files) { file in
                FileRow(file: file)
                    .tag(file.path)
            }
        } label: {
            HStack {
                Text(".\(fileExtension)")
                    .font(.headline.monospaced())
                
                Text("\(files.count) files")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let info = inconsistencyInfo {
                    Label("\(info.differentIconCount) different icons", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if customIconCount > 0 {
                    Text("\(customIconCount) with custom icons")
                        .font(.caption)
                        .foregroundStyle(.tint)
                }
            }
        }
        .sheet(isPresented: $showFixSheet) {
            if let info = inconsistencyInfo {
                FixInconsistencySheet(info: info)
            }
        }
    }
}

struct InconsistencyAlert: View {
    let info: InconsistencyInfo
    let onFix: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(info.outlierFiles.count) files have different icons")
                    .font(.subheadline.bold())
                Text("Apply the most common icon to all .\(info.fileExtension) files?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Fix") {
                onFix()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(10)
        .background(.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.vertical, 4)
    }
}

struct FixInconsistencySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    let info: InconsistencyInfo
    
    @State private var isApplying = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Fix Icon Inconsistency")
                .font(.title2.bold())
            
            HStack(spacing: 20) {
                VStack {
                    if let icon = info.dominantIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 64, height: 64)
                    }
                    Text("Most common icon")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(info.totalFiles - info.outlierFiles.count) files")
                        .font(.caption2)
                }
                
                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                VStack {
                    Text("\(info.outlierFiles.count)")
                        .font(.largeTitle.bold())
                    Text("files to update")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text("This will apply the most common icon to all .\(info.fileExtension) files that currently have a different icon.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button {
                    applyFix()
                } label: {
                    if isApplying {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Apply to \(info.outlierFiles.count) files")
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(isApplying)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
    
    private func applyFix() {
        guard let icon = info.dominantIcon else { return }
        isApplying = true
        
        Task {
            let urls = info.outlierFiles.map { $0.url }
            _ = appState.iconService.batchApply(icon: icon, to: urls) { _, _ in }
            
            appState.logActivity(ActivityEntry(
                action: .batchApplied,
                filePaths: urls.map { $0.path }
            ))
            
            isApplying = false
            dismiss()
        }
    }
}

struct FileRow: View {
    let file: FileTypeInfo
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = file.currentIcon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 24, height: 24)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.filename)
                    .font(.body)
                
                if file.isIconSmithApplied {
                    Text("IconSmith applied")
                        .font(.caption2)
                        .foregroundStyle(.tint)
                } else if file.hasCustomIcon {
                    Text("Custom icon")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
