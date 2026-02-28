@testable import AtomicArch
import Foundation

// Helper for generating test data for tests

enum TestData {
  static func mockUser(id: UUID = UUID(), login: String = "testuser") -> UserEntity {
    UserEntity(
      id: id,
      login: login,
      avatarUrl: "https://example.com/avatar.jpg",
      htmlUrl: "https://github.com/\(login)"
    )
  }

  static func mockUserDetail(
    id: Int = 1,
    login: String = "testuser",
    name: String = "Test User"
  )
    -> UserDetailEntity
  {
    UserDetailEntity(
      id: id,
      login: login,
      avatarUrl: "https://example.com/avatar.jpg",
      htmlUrl: "https://github.com/\(login)",
      name: name,
      company: "Test Company",
      blog: "https://test.blog",
      location: "Test Location",
      email: "test@example.com",
      bio: "Test Bio",
      publicRepos: 10,
      publicGists: 5,
      followers: 100,
      following: 50
    )
  }

  static func mockUsers(count: Int, startIndex: Int = 0) -> [UserEntity] {
    (startIndex ..< (startIndex + count)).map { index in
      UserEntity(
        id: UUID(),
        login: "user\(index)",
        avatarUrl: "avatar\(index)",
        htmlUrl: "html\(index)"
      )
    }
  }

  static func mockUserDetail() -> UserDetailEntity {
    UserDetailEntity(
      id: 12345,
      login: "johndoe",
      avatarUrl: "https://avatars.githubusercontent.com/u/12345",
      htmlUrl: "https://github.com/johndoe",
      name: "John Doe",
      company: "Tech Corp",
      blog: "https://johndoe.dev",
      location: "San Francisco, CA",
      email: "john@example.com",
      bio: "Software developer passionate about Swift and iOS development",
      publicRepos: 42,
      publicGists: 15,
      followers: 230,
      following: 185
    )
  }

  static func mockError(message: String) -> NSError {
    NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
  }
}
