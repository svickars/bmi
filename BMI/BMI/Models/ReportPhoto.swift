import Foundation
import SwiftData
import UIKit

@Model
final class ReportPhoto {
    var id: UUID
    var imageData: Data
    var caption: String
    var createdAt: Date
    var sortIndex: Int
    var cloudRecordName: String?
    var lastSyncedAt: Date?

    @Relationship(inverse: \BigMacReport.photos)
    var report: BigMacReport?

    var isSynced: Bool {
        cloudRecordName != nil && lastSyncedAt != nil
    }

    init(
        id: UUID = UUID(),
        imageData: Data,
        caption: String = "",
        createdAt: Date = .now,
        sortIndex: Int = 0,
        cloudRecordName: String? = nil,
        lastSyncedAt: Date? = nil
    ) {
        self.id = id
        self.imageData = imageData
        self.caption = caption
        self.createdAt = createdAt
        self.sortIndex = sortIndex
        self.cloudRecordName = cloudRecordName
        self.lastSyncedAt = lastSyncedAt
    }
}

enum PhotoCompression {
    static func jpegData(from data: Data, maxBytes: Int = 900_000, maxDimension: CGFloat = 1600) -> Data? {
        guard let image = UIImage(data: data) else { return data.count <= maxBytes ? data : nil }

        let resized = resize(image: image, maxDimension: maxDimension)
        var quality: CGFloat = 0.82
        var output = resized.jpegData(compressionQuality: quality)

        while let current = output, current.count > maxBytes, quality > 0.35 {
            quality -= 0.08
            output = resized.jpegData(compressionQuality: quality)
        }

        return output
    }

    private static func resize(image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let largestSide = max(size.width, size.height)
        guard largestSide > maxDimension else { return image }

        let scale = maxDimension / largestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
