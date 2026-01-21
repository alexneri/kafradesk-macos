import AppKit
import os

enum CharacterImageProvider {
    private static var cache: [String: NSImage] = [:]

    static func image(named name: String) -> NSImage? {
        if let cached = cache[name] {
            return cached
        }

        guard let image = NSImage(named: name) else {
            AppLogger.app.error("Missing image asset: \(name)")
            return nil
        }

        let processed = image.applyingColorKeyFromTopLeft(tolerance: 8)
        cache[name] = processed
        return processed
    }
}

private extension NSImage {
    func applyingColorKeyFromTopLeft(tolerance: UInt8) -> NSImage {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return self
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let totalBytes = height * bytesPerRow

        var data = [UInt8](repeating: 0, count: totalBytes)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return self
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let topLeftOffset = (height - 1) * bytesPerRow
        if topLeftOffset + 3 >= data.count {
            return self
        }

        let keyR = data[topLeftOffset]
        let keyG = data[topLeftOffset + 1]
        let keyB = data[topLeftOffset + 2]

        for y in 0..<height {
            let rowStart = y * bytesPerRow
            for x in 0..<width {
                let idx = rowStart + x * bytesPerPixel
                let r = data[idx]
                let g = data[idx + 1]
                let b = data[idx + 2]

                if abs(Int(r) - Int(keyR)) <= tolerance,
                   abs(Int(g) - Int(keyG)) <= tolerance,
                   abs(Int(b) - Int(keyB)) <= tolerance {
                    data[idx + 3] = 0
                }
            }
        }

        guard let outputImage = context.makeImage() else {
            return self
        }

        return NSImage(cgImage: outputImage, size: NSSize(width: width, height: height))
    }
}
