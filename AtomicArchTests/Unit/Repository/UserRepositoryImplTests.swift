@testable import AtomicArch
import Networking
import XCTest

final class MockNetworkService: NetworkService {
  var requestHandler: ((Target) async throws -> Any)?
  func request<T: Decodable>(_ target: Target) async throws -> T {
    if let handler = requestHandler {
      let result = try await handler(target)
      guard let typed = result as? T else {
        throw NetworkError.decodingError(NSError(domain: "", code: -1))
      }
      return typed
    }
    throw NetworkError.unknown
  }
}

final class UserRepositoryImplTests: XCTestCase {
  var networkService: MockNetworkService!
  var repository: UserRepositoryImpl!

  override func setUp() {
    super.setUp()
    self.networkService = MockNetworkService()
    self.repository = UserRepositoryImpl(networkService: self.networkService)
  }

  override func tearDown() {
    self.networkService = nil
    self.repository = nil
    super.tearDown()
  }

  func test_getListUser_success() async throws {
    // Arrange
    let userResponses = [UserResponse(id: 1, login: "test", avatarUrl: "url", htmlUrl: "html")]
    self.networkService.requestHandler = { _ in userResponses }

    // Act
    let users = try await repository.getListUser(perPage: 10, since: 0)

    // Assert
    XCTAssertEqual(users.count, 1)
    XCTAssertEqual(users[0].login, "test")
    XCTAssertEqual(users[0].avatarUrl, "url")
    XCTAssertEqual(users[0].htmlUrl, "html")
  }

  func test_getListUser_passesCorrectPathToEndpoint() async throws {
    // Arrange
    let userResponses = [UserResponse(id: 1, login: "test", avatarUrl: "url", htmlUrl: "html")]
    var capturedTarget: Target?
    self.networkService.requestHandler = { target in
      capturedTarget = target
      return userResponses
    }

    // Act
    _ = try await self.repository.getListUser(perPage: 20, since: 100)

    // Assert
    XCTAssertEqual(capturedTarget?.path, "/users")
  }

  func test_getListUser_failure() async {
    // Arrange
    self.networkService.requestHandler = { _ in throw NetworkError.noConnection }

    // Act & Assert
    await XCTAssertThrowsErrorAsync(try self.repository.getListUser(perPage: 10, since: 0)) { error in
      XCTAssertEqual(error as? NetworkError, .noConnection)
    }
  }

  func test_getUser_success() async throws {
    // Arrange
    let expected = UserDetailEntity(id: 1, login: "test", avatarUrl: "a", htmlUrl: "b", name: "Test User", company: "", blog: "", location: "", email: "", bio: "", publicRepos: 0, publicGists: 0, followers: 0, following: 0)
    let userDetailResponse = UserDetailResponse(
      id: 1,
      login: expected.login,
      avatarUrl: expected.avatarUrl,
      htmlUrl: expected.htmlUrl,
      name: expected.name,
      company: expected.company,
      blog: expected.blog,
      location: expected.location,
      email: expected.email,
      bio: expected.bio,
      publicRepos: expected.publicRepos,
      publicGists: expected.publicGists,
      followers: expected.followers,
      following: expected.following
    )
    self.networkService.requestHandler = { _ in userDetailResponse }

    // Act
    let detail = try await repository.getUser(with: "test")

    // Assert
    XCTAssertEqual(detail, expected)
  }

  func test_getUser_passesUsernameToEndpoint() async throws {
    // Arrange
    let json = """
    {"id":1,"login":"octocat","avatar_url":"a","html_url":"b","name":"Octo"}
    """
    let response = try JSONDecoder().decode(UserDetailResponse.self, from: XCTUnwrap(json.data(using: .utf8)))
    var capturedTarget: Target?
    self.networkService.requestHandler = { target in
      capturedTarget = target
      return response
    }

    // Act
    _ = try await self.repository.getUser(with: "octocat")

    // Assert
    XCTAssertEqual(capturedTarget?.path, "/users/octocat")
  }

  func test_getUser_failure() async {
    // Arrange
    self.networkService.requestHandler = { _ in throw NetworkError.noConnection }

    // Act & Assert
    await XCTAssertThrowsErrorAsync(try self.repository.getUser(with: "test")) { error in
      XCTAssertEqual(error as? NetworkError, .noConnection)
    }
  }
}
