import Foundation
import SwiftData

@Model
final class HistoryEntry {
    var title: String
    var urlString: String
    var visitedAt: Date

    init(title: String, url: URL) {
        self.title = title
        self.urlString = url.absoluteString
        self.visitedAt = .now
    }

    var url: URL? {
        URL(string: urlString)
    }
}
