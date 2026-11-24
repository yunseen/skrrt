import Foundation
import SwiftData

@Model
final class Bookmark {
    var title: String
    var urlString: String
    var createdAt: Date

    init(title: String, url: URL) {
        self.title = title
        self.urlString = url.absoluteString
        self.createdAt = .now
    }

    var url: URL? {
        URL(string: urlString)
    }
}
