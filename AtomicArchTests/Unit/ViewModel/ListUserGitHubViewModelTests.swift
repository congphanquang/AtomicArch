@testable import AtomicArch
import Combine
import Networking
import XCTest

final class ListUserGitHubViewModelTests: XCTestCase {
  private var sut: ListUserGitHubViewModel!
  private var mockUseCase: UserUseCaseMock!
  private var cancellables: Set<AnyCancellable>!

  override func setUp() {
    super.setUp()
    self.mockUseCase = UserUseCaseMock()
    self.sut = ListUserGitHubViewModel(userUseCase: self.mockUseCase)
    self.cancellables = []
  }

  override func tearDown() {
    self.sut = nil
    self.mockUseCase = nil
    self.cancellables = nil
    super.tearDown()
  }

  func testInitialState() {
    XCTAssertTrue(self.sut.users.isEmpty)
  }

  func test_initialState_isIdle() {
    XCTAssertEqual(self.sut.viewState, .idle)
  }

  func test_loadUsers_success() async {
    // Arrange
    let expected = [UserEntity(id: UUID(), login: "test", avatarUrl: "url", htmlUrl: "html")]
    self.mockUseCase.getListUserHandler = { _, _ in expected }

    let expectation = XCTestExpectation(description: "Should emit .loading then .loaded")
    var states: [ListUserGitHubViewModel.ViewState] = []

    self.sut.$viewState
      .dropFirst() // skip initial .idle
      .sink { state in
        states.append(state)
        if states.count == 2 { expectation.fulfill() }
      }
      .store(in: &self.cancellables)

    // Act
    await self.sut.loadUsers()

    // Assert
    wait(for: [expectation], timeout: 1)
    XCTAssertEqual(states.first, .loading)
    XCTAssertEqual(states.last, .loaded(expected))
    XCTAssertEqual(self.mockUseCase.getListUserCallCount, 1)
  }

  func test_loadUsers_failure() async {
    // Arrange
    self.mockUseCase.getListUserHandler = { _, _ in throw NetworkError.noConnection }

    let expectation = XCTestExpectation(description: "Should emit .loading then .error")
    var states: [ListUserGitHubViewModel.ViewState] = []

    self.sut.$viewState
      .dropFirst() // skip initial .idle
      .sink { state in
        states.append(state)
        if states.count == 2 { expectation.fulfill() }
      }
      .store(in: &self.cancellables)

    // Act
    await self.sut.loadUsers()

    // Assert
    wait(for: [expectation], timeout: 1)
    XCTAssertEqual(states.first, .loading)
    XCTAssertEqual(states.last, .error)
    XCTAssertEqual(self.mockUseCase.getListUserCallCount, 1)
  }

  func test_loadMoreIfNeeded_appendsUsers() async {
    // Arrange: Initial users
    let firstBatch = [
      UserEntity(id: UUID(), login: "user1", avatarUrl: "a", htmlUrl: "a"),
      UserEntity(id: UUID(), login: "user2", avatarUrl: "b", htmlUrl: "b")
    ]
    let secondBatch = [
      UserEntity(id: UUID(), login: "user3", avatarUrl: "c", htmlUrl: "c"),
      UserEntity(id: UUID(), login: "user4", avatarUrl: "d", htmlUrl: "d")
    ]
    var callCount = 0
    self.mockUseCase.getListUserHandler = { _, since in
      callCount += 1
      return since == 0 ? firstBatch : secondBatch
    }

    // Load first batch
    await self.sut.loadUsers()
    XCTAssertEqual(self.sut.users, firstBatch)

    // Act: Load more with the last user
    await self.sut.loadUsers(since: firstBatch.count)

    // Assert: Users should be appended
    XCTAssertEqual(self.sut.users.count, 4)
    XCTAssertEqual(self.mockUseCase.getListUserCallCount, 2)
  }

  func test_loadMoreIfNeeded_doesNotDuplicateUsers() async {
    // Arrange
    let user1 = UserEntity(id: UUID(), login: "user1", avatarUrl: "a", htmlUrl: "a")
    let user2 = UserEntity(id: UUID(), login: "user2", avatarUrl: "b", htmlUrl: "b")
    let user3 = UserEntity(id: UUID(), login: "user3", avatarUrl: "c", htmlUrl: "c")
    self.mockUseCase.getListUserHandler = { _, since in
      since == 0 ? [user1, user2] : [user2, user3] // user2 is duplicate
    }

    // Load first batch
    await self.sut.loadUsers()
    XCTAssertEqual(self.sut.users, [user1, user2])

    // Act: Load more with the last user
    await self.sut.loadUsers(since: 2)

    // Assert: user2 should not be duplicated; we should have 3 unique users
    XCTAssertEqual(self.sut.users.count, 3)
    XCTAssertEqual(self.sut.users.map(\.login), ["user1", "user2", "user3"])
  }

  func test_loadUsers_retryAfterFailure() async {
    // Arrange: First call fails, second call succeeds
    var callCount = 0
    let expected = [UserEntity(id: UUID(), login: "test", avatarUrl: "url", htmlUrl: "html")]
    self.mockUseCase.getListUserHandler = { _, _ in
      callCount += 1
      if callCount == 1 {
        throw NetworkError.noConnection
      } else {
        return expected
      }
    }

    let expectation = XCTestExpectation(description: "Should emit .loading, .error, .loading, .loaded")
    var states: [ListUserGitHubViewModel.ViewState] = []

    self.sut.$viewState
      .dropFirst() // skip initial .idle
      .sink { state in
        states.append(state)
        if states.count == 4 { expectation.fulfill() }
      }
      .store(in: &self.cancellables)

    // Act: First attempt (fail)
    await self.sut.loadUsers()
    // Retry (success)
    await self.sut.loadUsers()

    // Assert
    wait(for: [expectation], timeout: 1)
    XCTAssertEqual(states[0], .loading)
    XCTAssertEqual(states[1], .error)
    XCTAssertEqual(states[2], .loading)
    XCTAssertEqual(states[3], .loaded(expected))
  }
}
