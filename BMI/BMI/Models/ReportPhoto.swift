import Foundation
import SwiftData

@Model
final class ReportPhoto {
    var id: UUID
    var imageData: Data
    var caption: String
    var createdAt: Date

    @Relationship(inverse: \BigMacReport.photos)
    var report: BigMacReport?

    init(
        id: UUID = UUID(),
        imageData: Data,
        caption: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.imageData = imageData
        self.caption = caption
        self.createdAt = createdAt
    }
}
