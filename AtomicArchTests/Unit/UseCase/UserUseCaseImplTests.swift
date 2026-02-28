@testable import AtomicArch
import Networking
import XCTest

final class UserUseCaseImplTests: XCTestCase {
  var repository: UserRepositoryMock!
  var useCase: UserUseCaseImpl!

  override func setUp() {
    super.setUp()
    self.repository = UserRepositoryMock()
    self.useCase = UserUseCaseImpl(repository: self.repository)
  }

  override func tearDown() {
    self.repository = nil
    self.useCase = nil
    super.tearDown()
  }

  func test_getListUser_success() async throws {
    // Arrange
    let expectedUsers = [UserEntity(id: UUID(), login: "test", avatarUrl: "url", htmlUrl: "html")]
    self.repository.getListUserHandler = { _, _ in expectedUsers }

    // Act
    let users = try await useCase.getListUser(perPage: 10, since: 0)

    // Assert
    XCTAssertEqual(users, expectedUsers)
    XCTAssertEqual(self.repository.getListUserCallCount, 1)
  }

  func test_getListUser_failure() async {
    // Arrange
    self.repository.getListUserHandler = { _, _ in throw NetworkError.noConnection }

    // Act & Assert
    await XCTAssertThrowsErrorAsync(try self.useCase.getListUser(perPage: 10, since: 0)) { error in
      XCTAssertEqual(error as? NetworkError, .noConnection)
    }
    XCTAssertEqual(self.repository.getListUserCallCount, 1)
  }

  func test_getUser_success() async throws {
    // Arrange
    let expectedDetail = UserDetailEntity(
      id: 1, login: "test", avatarUrl: "a", htmlUrl: "b", name: "Test User", company: "", blog: "", location: "", email: "", bio: "", publicRepos: 0, publicGists: 0, followers: 0, following: 0
    )
    self.repository.getUserHandler = { _ in expectedDetail }

    // Act
    let detail = try await useCase.getUser(with: "test")

    // Assert
    XCTAssertEqual(detail, expectedDetail)
    XCTAssertEqual(self.repository.getUserCallCount, 1)
  }

  func test_getUser_failure() async {
    // Arrange
    self.repository.getUserHandler = { _ in throw NetworkError.noConnection }

    // Act & Assert
    await XCTAssertThrowsErrorAsync(try self.useCase.getUser(with: "test")) { error in
      XCTAssertEqual(error as? NetworkError, .noConnection)
    }
    XCTAssertEqual(self.repository.getUserCallCount, 1)
  }
}
