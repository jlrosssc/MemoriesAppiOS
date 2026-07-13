import Foundation

struct SavedServer: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var url: String
    var username: String

    var displayName: String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.isEmpty else { return trimmedName }
        return URL(string: url)?.host ?? url
    }

    init(id: UUID = UUID(), name: String, url: String, username: String = "") {
        self.id = id
        self.name = name
        self.url = url
        self.username = username
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case url
        case username
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        url = try container.decode(String.self, forKey: .url)
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
    }
}
