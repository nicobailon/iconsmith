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
    
    var customIconCount: Int {
        files.filter { $0.hasCustomIcon }.count
    }
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
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
                
                if customIconCount > 0 {
                    Text("\(customIconCount) with custom icons")
                        .font(.caption)
                        .foregroundStyle(.tint)
                }
            }
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
