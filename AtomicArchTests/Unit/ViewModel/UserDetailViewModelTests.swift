@testable import AtomicArch
import Combine
@testable import Networking
import XCTest

final class UserDetailViewModelTests: XCTestCase {
  private var sut: UserDetailViewModel!
  private var mockUserUseCase: UserUseCaseMock!
  private var cancellables: Set<AnyCancellable>!

  override func setUp() {
    super.setUp()
    self.mockUserUseCase = UserUseCaseMock()
    self.sut = UserDetailViewModel(userUseCase: self.mockUserUseCase, username: "testuser")
    self.cancellables = []
  }

  override func tearDown() {
    self.sut = nil
    self.mockUserUseCase = nil
    self.cancellables = nil
    super.tearDown()
  }

  // MARK: - Initial State Tests

  func testInitialState() {
    XCTAssertEqual(self.sut.viewState, .idle)
    XCTAssertNil(self.sut.user)
  }

  // MARK: - Load User Tests

  func testLoadUserSuccess() async {
    // Given
    let mockUser = UserDetailEntity(
      id: 1,
      login: "testuser",
      avatarUrl: "avatar_url",
      htmlUrl: "html_url",
      name: "Test User",
      company: "Test Company",
      blog: "test.blog",
      location: "Test Location",
      email: "test@email.com",
      bio: "Test Bio",
      publicRepos: 10,
      publicGists: 5,
      followers: 100,
      following: 50
    )
    self.mockUserUseCase.getUserHandler = { _ in mockUser }

    let expectation = expectation(description: "View state should be updated")
    var viewStates: [UserDetailViewModel.ViewState] = []

    self.sut.$viewState
      .sink { state in
        viewStates.append(state)
        if case .loaded = state {
          expectation.fulfill()
        }
      }
      .store(in: &self.cancellables)

    // When
    let input = UserDetailViewModel.Input(
      loadUser: Just(()).eraseToAnyPublisher()
    )
    _ = self.sut.transform(input: input)

    // Then
    await fulfillment(of: [expectation], timeout: 1.0)
    XCTAssertEqual(viewStates.count, 3) // idle -> loading -> loaded
    XCTAssertEqual(self.mockUserUseCase.getUserCallCount, 1)

    if case let .loaded(user) = viewStates.last {
      XCTAssertEqual(user.login, "testuser")
      XCTAssertEqual(user.name, "Test User")
      XCTAssertEqual(user.company, "Test Company")
      XCTAssertEqual(user.publicRepos, 10)
      XCTAssertEqual(user.followers, 100)
      XCTAssertEqual(user.following, 50)
    } else {
      XCTFail("Expected loaded state")
    }
  }

  func testLoadUserFailure() async {
    // Given
    self.mockUserUseCase.getUserHandler = { _ in throw NetworkError.noConnection }

    let expectation = expectation(description: "View state should be updated")
    var viewStates: [UserDetailViewModel.ViewState] = []

    self.sut.$viewState
      .sink { state in
        viewStates.append(state)
        if case .error = state {
          expectation.fulfill()
        }
      }
      .store(in: &self.cancellables)

    // When
    let input = UserDetailViewModel.Input(
      loadUser: Just(()).eraseToAnyPublisher()
    )
    _ = self.sut.transform(input: input)

    // Then
    await fulfillment(of: [expectation], timeout: 1.0)
    XCTAssertEqual(viewStates.count, 3) // idle -> loading -> error
    XCTAssertEqual(self.mockUserUseCase.getUserCallCount, 1)

    if case let .error(error) = viewStates.last {
      XCTAssertEqual(error as? NetworkError, .noConnection)
    } else {
      XCTFail("Expected error state")
    }
  }

  // MARK: - State Transition Tests

  func testStateTransitions() async {
    // Given
    let mockUser = UserDetailEntity(
      id: 1,
      login: "testuser",
      avatarUrl: "avatar_url",
      htmlUrl: "html_url",
      name: "Test User",
      company: "Test Company",
      blog: "test.blog",
      location: "Test Location",
      email: "test@email.com",
      bio: "Test Bio",
      publicRepos: 10,
      publicGists: 5,
      followers: 100,
      following: 50
    )
    self.mockUserUseCase.getUserHandler = { _ in mockUser }

    let expectation = expectation(description: "View state should be updated")
    var viewStates: [UserDetailViewModel.ViewState] = []

    self.sut.$viewState
      .sink { state in
        viewStates.append(state)
        if case .loaded = state {
          expectation.fulfill()
        }
      }
      .store(in: &self.cancellables)

    // When
    let input = UserDetailViewModel.Input(
      loadUser: Just(()).eraseToAnyPublisher()
    )
    _ = self.sut.transform(input: input)

    // Then
    await fulfillment(of: [expectation], timeout: 1.0)
    XCTAssertEqual(viewStates.count, 3)
    XCTAssertEqual(viewStates[0], .idle)
    XCTAssertEqual(viewStates[1], .loading)
    if case .loaded = viewStates[2] {
      // Success
    } else {
      XCTFail("Expected loaded state")
    }
  }

  // MARK: - Edge Cases Tests

  func testLoadUserWithInvalidUsername() async {
    // Given
    let invalidUsername = ""
    self.sut = UserDetailViewModel(userUseCase: self.mockUserUseCase, username: invalidUsername)
    self.mockUserUseCase.getUserHandler = { _ in throw NetworkError.invalidURL }

    let expectation = expectation(description: "View state should be updated")
    var viewStates: [UserDetailViewModel.ViewState] = []

    self.sut.$viewState
      .sink { state in
        viewStates.append(state)
        if case .error = state {
          expectation.fulfill()
        }
      }
      .store(in: &self.cancellables)

    // When
    let input = UserDetailViewModel.Input(
      loadUser: Just(()).eraseToAnyPublisher()
    )
    _ = self.sut.transform(input: input)

    // Then
    await fulfillment(of: [expectation], timeout: 1.0)
    XCTAssertEqual(viewStates.count, 3) // idle -> loading -> error
    XCTAssertEqual(self.mockUserUseCase.getUserCallCount, 1)

    if case let .error(error) = viewStates.last {
      XCTAssertNotNil(error)
    } else {
      XCTFail("Expected error state")
    }
  }

  func testLoadUserWithPartialData() async {
    // Given
    let mockUser = UserDetailEntity(
      id: 1,
      login: "testuser",
      avatarUrl: "avatar_url",
      htmlUrl: "html_url",
      name: "", // Empty string instead of nil
      company: "",
      blog: "",
      location: "",
      email: "",
      bio: "",
      publicRepos: 0,
      publicGists: 0,
      followers: 0,
      following: 0
    )
    self.mockUserUseCase.getUserHandler = { _ in mockUser }

    let expectation = expectation(description: "View state should be updated")
    var viewStates: [UserDetailViewModel.ViewState] = []

    self.sut.$viewState
      .sink { state in
        viewStates.append(state)
        if case .loaded = state {
          expectation.fulfill()
        }
      }
      .store(in: &self.cancellables)

    // When
    let input = UserDetailViewModel.Input(
      loadUser: Just(()).eraseToAnyPublisher()
    )
    _ = self.sut.transform(input: input)

    // Then
    await fulfillment(of: [expectation], timeout: 1.0)
    XCTAssertEqual(viewStates.count, 3) // idle -> loading -> loaded

    if case let .loaded(user) = viewStates.last {
      XCTAssertEqual(user.login, "testuser")
      XCTAssertEqual(user.name, "")
      XCTAssertEqual(user.company, "")
      XCTAssertEqual(user.publicRepos, 0)
      XCTAssertEqual(user.followers, 0)
    } else {
      XCTFail("Expected loaded state")
    }
  }

  func testConcurrentLoadRequests() async {
    // Given
    let mockUser = UserDetailEntity(
      id: 1,
      login: "testuser",
      avatarUrl: "avatar_url",
      htmlUrl: "html_url",
      name: "Test User",
      company: "Test Company",
      blog: "test.blog",
      location: "Test Location",
      email: "test@email.com",
      bio: "Test Bio",
      publicRepos: 10,
      publicGists: 5,
      followers: 100,
      following: 50
    )
    self.mockUserUseCase.getUserHandler = { _ in mockUser }

    let expectation = expectation(description: "View state should be updated")
    expectation.expectedFulfillmentCount = 2
    var viewStates: [UserDetailViewModel.ViewState] = []

    self.sut.$viewState
      .sink { state in
        viewStates.append(state)
        if case .loaded = state {
          expectation.fulfill()
        }
      }
      .store(in: &self.cancellables)

    // When
    let input = UserDetailViewModel.Input(
      loadUser: Just(()).eraseToAnyPublisher()
    )

    // Simulate concurrent requests by calling transform twice
    _ = await self.sut.transform(input: input)
    _ = await self.sut.transform(input: input)

    // Then
    await fulfillment(of: [expectation], timeout: 1.0)
    XCTAssertEqual(self.mockUserUseCase.getUserCallCount, 2)
  }

  func testRetryMechanism() async {
    // Given
    let mockError = NetworkError.noConnection
    let mockUser = UserDetailEntity(
      id: 1,
      login: "testuser",
      avatarUrl: "avatar_url",
      htmlUrl: "html_url",
      name: "Test User",
      company: "Test Company",
      blog: "test.blog",
      location: "Test Location",
      email: "test@email.com",
      bio: "Test Bio",
      publicRepos: 10,
      publicGists: 5,
      followers: 100,
      following: 50
    )

    // First attempt fails
    self.mockUserUseCase.getUserHandler = { _ in throw mockError }

    let errorExpectation = expectation(description: "Error state should be reached")
    let successExpectation = expectation(description: "Success state should be reached")
    var viewStates: [UserDetailViewModel.ViewState] = []

    self.sut.$viewState
      .sink { state in
        viewStates.append(state)
        if case .error = state {
          errorExpectation.fulfill()
        }
        if case .loaded = state {
          successExpectation.fulfill()
        }
      }
      .store(in: &self.cancellables)

    // When
    let input = UserDetailViewModel.Input(
      loadUser: Just(()).eraseToAnyPublisher()
    )
    _ = self.sut.transform(input: input)

    // Wait for error
    await fulfillment(of: [errorExpectation], timeout: 1.0)

    // Second attempt succeeds
    self.mockUserUseCase.getUserHandler = { _ in mockUser }

    // Retry
    _ = self.sut.transform(input: input)

    // Then
    await fulfillment(of: [successExpectation], timeout: 1.0)
    XCTAssertEqual(viewStates.count, 5) // idle -> loading -> error -> loading -> loaded
    XCTAssertEqual(self.mockUserUseCase.getUserCallCount, 2)
  }
}
