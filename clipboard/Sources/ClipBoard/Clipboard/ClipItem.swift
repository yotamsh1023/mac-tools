import Foundation

struct ClipItem: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    var isPinned: Bool
    let contentType: ContentType
    let textContent: String?
    let imageData: Data?
    let fileURL: String?
    var searchableText: String

    enum ContentType: String, Codable {
        case text, image, fileURL
    }

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        isPinned: Bool = false,
        contentType: ContentType,
        textContent: String? = nil,
        imageData: Data? = nil,
        fileURL: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.contentType = contentType
        self.textContent = textContent
        self.imageData = imageData
        self.fileURL = fileURL

        switch contentType {
        case .text:
            self.searchableText = textContent ?? ""
        case .fileURL:
            let path = fileURL ?? ""
            self.searchableText = URL(fileURLWithPath: path).lastPathComponent
        case .image:
            self.searchableText = ""
        }
    }

    var preview: String {
        switch contentType {
        case .text:
            return textContent ?? ""
        case .fileURL:
            let path = fileURL ?? ""
            return URL(fileURLWithPath: path).lastPathComponent
        case .image:
            return "[Image]"
        }
    }

    var contentHash: Int {
        switch contentType {
        case .text: return textContent?.hashValue ?? 0
        case .image: return imageData?.hashValue ?? 0
        case .fileURL: return fileURL?.hashValue ?? 0
        }
    }
}
