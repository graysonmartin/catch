import Foundation
import ImageIO
import CoreGraphics

/// Strips EXIF metadata (GPS, device info, timestamps) from JPEG image data
/// to prevent PII leaks when uploading to public storage buckets.
enum EXIFStripper {

    /// Removes all metadata dictionaries from image data — GPS coordinates,
    /// device info, timestamps, and IPTC/TIFF fields.
    ///
    /// Returns the original data unchanged if stripping fails (e.g. invalid input),
    /// so the upload path is never blocked by metadata removal issues.
    static func stripMetadata(from data: Data) -> Data {
        guard !data.isEmpty else { return data }

        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let uti = CGImageSourceGetType(source),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return data
        }

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            uti,
            1,
            nil
        ) else {
            return data
        }

        // Build clean properties with only non-PII fields.
        // Compression quality 1.0 prevents further quality loss from re-encoding —
        // photos are already JPEG-compressed before reaching this function.
        var cleanProperties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 1.0
        ]

        if let existingProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {
            let safeKeys: Set<CFString> = [
                kCGImagePropertyPixelWidth,
                kCGImagePropertyPixelHeight,
                kCGImagePropertyDPIWidth,
                kCGImagePropertyDPIHeight,
                kCGImagePropertyOrientation,
                kCGImagePropertyColorModel,
                kCGImagePropertyDepth,
                kCGImagePropertyProfileName,
                "ICCProfile" as CFString,
                kCGImagePropertyHasAlpha
            ]

            for (key, value) in existingProperties {
                if safeKeys.contains(key) {
                    cleanProperties[key] = value
                }
            }

            // Preserve JFIF dictionary (JPEG structural metadata, no PII)
            if let jfif = existingProperties[kCGImagePropertyJFIFDictionary] {
                cleanProperties[kCGImagePropertyJFIFDictionary] = jfif
            }
        }

        CGImageDestinationAddImage(destination, cgImage, cleanProperties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            return data
        }

        return mutableData as Data
    }
}
