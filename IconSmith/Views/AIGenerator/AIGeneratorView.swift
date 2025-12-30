import SwiftUI

struct AIGeneratorView: View {
    @EnvironmentObject var appState: AppState
    @State private var prompt = ""
    @State private var selectedStyle: GeminiService.Style = .bigSur
    @State private var accentColor: Color = .blue
    @State private var showAPIKeySetup = false
    @State private var isGenerating = false
    @State private var generatedImage: NSImage?
    @State private var errorMessage: String?
    
    let templates = [
        ("File icon for [extension]", "File icon for typescript with code symbols"),
        ("Programming language icon", "Programming language icon for Rust with crab motif"),
        ("Document type icon", "Document type icon for markdown with text lines"),
        ("Config file icon", "Config file icon with gear symbol")
    ]
    
    var body: some View {
        HSplitView {
            inputPanel
                .frame(width: 320)
            
            previewPanel
        }
        .navigationTitle("Generate Icon")
        .sheet(isPresented: $showAPIKeySetup) {
            APIKeySetupSheet()
        }
    }
    
    private var inputPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Generate Icon")
                .font(.title2.bold())
            
            if !appState.geminiService.hasAPIKey {
                apiKeyWarning
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Start from template:")
                    .font(.headline)
                
                ForEach(templates, id: \.0) { template in
                    Button(template.0) {
                        prompt = template.1
                    }
                    .buttonStyle(.link)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Prompt:")
                    .font(.headline)
                
                TextEditor(text: $prompt)
                    .font(.body)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }
            
            Picker("Style:", selection: $selectedStyle) {
                ForEach(GeminiService.Style.allCases) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            
            ColorPicker("Accent Color:", selection: $accentColor)
            
            Button {
                generateIcon()
            } label: {
                if isGenerating {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Generate Icon")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(prompt.isEmpty || isGenerating || !appState.geminiService.hasAPIKey)
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var apiKeyWarning: some View {
        HStack(spacing: 12) {
            Image(systemName: "key.fill")
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("API Key Required")
                    .font(.headline)
                Text("Configure your Gemini API key to generate icons")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Setup") {
                showAPIKeySetup = true
            }
        }
        .padding()
        .background(.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var previewPanel: some View {
        VStack {
            if isGenerating {
                ProgressView("Generating...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let image = generatedImage {
                GeneratedImagePreview(
                    image: image,
                    onSave: { saveToLibrary($0) },
                    onRegenerate: { generateIcon() }
                )
            } else {
                ContentUnavailableView(
                    "No Generated Icon",
                    systemImage: "wand.and.stars",
                    description: Text("Enter a prompt and generate an icon")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func generateIcon() {
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let colorName = colorToString(accentColor)
                let request = GeminiService.GenerationRequest(
                    prompt: prompt,
                    style: selectedStyle,
                    accentColor: colorName
                )
                generatedImage = try await appState.geminiService.generateIcon(request)
            } catch {
                errorMessage = error.localizedDescription
            }
            isGenerating = false
        }
    }
    
    private func saveToLibrary(_ image: NSImage) {
        let id = UUID()
        let filename = "\(id.uuidString).png"
        
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let iconDir = appSupport.appendingPathComponent("IconSmith/Icons/generated")
        let iconPath = iconDir.appendingPathComponent(filename)
        
        if let pngData = ICNSConverter.pngData(from: image) {
            try? FileManager.default.createDirectory(at: iconDir, withIntermediateDirectories: true)
            try? pngData.write(to: iconPath)
            
            let iconFile = IconFile(
                id: id,
                name: "Generated - \(prompt.prefix(20))",
                path: iconPath,
                category: .custom,
                source: .aiGenerated,
                dateAdded: Date(),
                usageCount: 0,
                associatedExtensions: []
            )
            appState.iconLibrary.addIcon(iconFile)
        }
    }
    
    private func colorToString(_ color: Color) -> String {
        guard let nsColor = NSColor(color).usingColorSpace(.sRGB) else {
            return "blue"
        }
        
        let r = nsColor.redComponent
        let g = nsColor.greenComponent
        let b = nsColor.blueComponent
        
        if r > 0.8 && g < 0.3 && b < 0.3 {
            return "red"
        } else if g > 0.8 && r < 0.3 && b < 0.3 {
            return "green"
        } else if b > 0.8 && r < 0.3 && g < 0.3 {
            return "blue"
        } else if r > 0.8 && g > 0.8 && b < 0.3 {
            return "yellow"
        } else if r > 0.8 && g > 0.4 && b < 0.3 {
            return "orange"
        } else if r > 0.8 && b > 0.8 && g < 0.3 {
            return "purple"
        }
        return "blue"
    }
}

struct GeneratedImagePreview: View {
    let image: NSImage
    let onSave: (NSImage) -> Void
    let onRegenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 256, height: 256)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.quaternary)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            HStack(spacing: 16) {
                Button("Regenerate") {
                    onRegenerate()
                }
                
                Button("Save to Library") {
                    onSave(image)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

struct APIKeySetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var apiKey = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Gemini API Key")
                .font(.title2.bold())
            
            Text("Enter your Google Gemini API key to enable AI icon generation. Get a key from Google AI Studio.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            SecureField("API Key", text: $apiKey)
                .textFieldStyle(.roundedBorder)
            
            Link("Get API Key from Google AI Studio", destination: URL(string: "https://aistudio.google.com/app/apikey")!)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                if appState.geminiService.hasAPIKey {
                    Button("Clear Key", role: .destructive) {
                        appState.geminiService.clearAPIKey()
                        dismiss()
                    }
                }
                
                Button("Save") {
                    appState.geminiService.setAPIKey(apiKey)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(apiKey.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}
