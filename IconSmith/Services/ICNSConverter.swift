import Foundation
import AppKit

final class ICNSConverter {
    
    enum ConversionError: LocalizedError {
        case failedToCreatePNG
        case iconutilFailed(Int32)
        case invalidImage
        
        var errorDescription: String? {
            switch self {
            case .failedToCreatePNG:
                return "Failed to create PNG data from image"
            case .iconutilFailed(let code):
                return "iconutil failed with exit code \(code)"
            case .invalidImage:
                return "Invalid or corrupted image"
            }
        }
    }
    
    static func convert(_ image: NSImage, to outputURL: URL) throws {
        guard image.isValid else {
            throw ConversionError.invalidImage
        }
        
        let iconsetURL = outputURL.deletingPathExtension().appendingPathExtension("iconset")
        try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: iconsetURL)
        }
        
        let sizes: [(name: String, size: Int)] = [
            ("icon_16x16", 16),
            ("icon_16x16@2x", 32),
            ("icon_32x32", 32),
            ("icon_32x32@2x", 64),
            ("icon_128x128", 128),
            ("icon_128x128@2x", 256),
            ("icon_256x256", 256),
            ("icon_256x256@2x", 512),
            ("icon_512x512", 512),
            ("icon_512x512@2x", 1024)
        ]
        
        for (name, size) in sizes {
            let resized = resize(image, to: CGSize(width: size, height: size))
            guard let pngData = pngData(from: resized) else {
                throw ConversionError.failedToCreatePNG
            }
            let fileURL = iconsetURL.appendingPathComponent("\(name).png")
            try pngData.write(to: fileURL)
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
        process.arguments = ["-c", "icns", iconsetURL.path, "-o", outputURL.path]
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw ConversionError.iconutilFailed(process.terminationStatus)
        }
    }
    
    static func pngData(from image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        return pngData
    }
    
    static func resize(_ image: NSImage, to size: CGSize) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(
            in: NSRect(origin: .zero, size: size),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        return newImage
    }
}
