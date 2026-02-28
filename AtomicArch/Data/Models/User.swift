import Foundation

struct UserResponse: Decodable {
  let id: Int
  let login: String?
  let avatarUrl: String?
  let htmlUrl: String?

  enum CodingKeys: String, CodingKey {
    case id
    case login
    case avatarUrl = "avatar_url"
    case htmlUrl = "html_url"
  }
}

extension UserResponse {
  func toDomain() -> UserEntity {
    UserEntity(
      id: Self.uuidFromAPIId(self.id),
      login: self.login ?? "",
      avatarUrl: self.avatarUrl ?? "",
      htmlUrl: self.htmlUrl ?? ""
    )
  }

  private static func uuidFromAPIId(_ id: Int) -> UUID {
    UUID(uuid: (
      0, 0, 0, 0, 0, 0, 0, 0,
      UInt8((id >> 56) & 0xFF),
      UInt8((id >> 48) & 0xFF),
      UInt8((id >> 40) & 0xFF),
      UInt8((id >> 32) & 0xFF),
      UInt8((id >> 24) & 0xFF),
      UInt8((id >> 16) & 0xFF),
      UInt8((id >> 8) & 0xFF),
      UInt8(id & 0xFF)
    ))
  }
}
