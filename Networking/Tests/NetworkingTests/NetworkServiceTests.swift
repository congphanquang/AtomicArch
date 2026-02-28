@testable import Networking
import XCTest

final class NetworkServiceTests: XCTestCase {
  // MARK: - Properties

  private var configuration: NetworkServiceImpl.Configuration!
  private var mockSession: MockNetworkSession!
  private var mockInterceptorChain: MockNetworkInterceptorChain!
  private var mockNetworkMonitor: MockNetworkMonitor!
  private var sut: NetworkService!

  // MARK: - Setup & Teardown

  override func setUp() {
    super.setUp()
    self.configuration = NetworkServiceImpl.Configuration(
      baseURL: URL(string: "https://api.example.com")!,
      timeoutInterval: 30,
      defaultHeaders: ["Content-Type": "application/json"]
    )
    self.mockSession = MockNetworkSession()
    self.mockInterceptorChain = MockNetworkInterceptorChain()
    self.mockNetworkMonitor = MockNetworkMonitor()
    self.sut = NetworkServiceImpl(
      configuration: self.configuration,
      session: self.mockSession,
      interceptorChain: self.mockInterceptorChain,
      networkMonitor: self.mockNetworkMonitor
    )
  }

  override func tearDown() {
    self.configuration = nil
    self.mockSession = nil
    self.mockInterceptorChain = nil
    self.mockNetworkMonitor = nil
    self.sut = nil
    super.tearDown()
  }

  // MARK: - Network Connectivity Tests

  func test_request_whenNoConnection_throwsError() async {
    // given
    self.mockNetworkMonitor.isConnected = false

    // when
    do {
      let _: TestResponse = try await sut.request(TestTarget())
      XCTFail("Expected error to be thrown")
    } catch {
      XCTAssertEqual(error as? NetworkError, .noConnection)
    }
  }

  // MARK: - Request Building Tests

  func test_request_buildsCorrectURL() async throws {
    // given
    let target = TestTarget(path: "test")
    let response = TestResponse(id: 1, name: "Test")
    let data = try JSONEncoder().encode(response)
    self.mockSession.mockResponse = try (data, XCTUnwrap(HTTPURLResponse(url: self.configuration.baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)))

    // when
    let _: TestResponse = try await sut.request(target)

    // then
    XCTAssertEqual(self.mockSession.lastRequest?.url?.absoluteString, "https://api.example.com/test")
  }

  func test_request_setsCorrectHTTPMethod() async throws {
    // given
    let target = TestTarget(method: .post)
    let response = TestResponse(id: 1, name: "Test")
    let data = try JSONEncoder().encode(response)
    self.mockSession.mockResponse = try (data, XCTUnwrap(HTTPURLResponse(url: self.configuration.baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)))

    // when
    let _: TestResponse = try await sut.request(target)

    // then
    XCTAssertEqual(self.mockSession.lastRequest?.httpMethod, "POST")
  }

  func test_request_setsCorrectHeaders() async throws {
    // given
    let target = TestTarget(headers: ["Custom": "Header"])
    let response = TestResponse(id: 1, name: "Test")
    let data = try JSONEncoder().encode(response)
    self.mockSession.mockResponse = try (data, XCTUnwrap(HTTPURLResponse(url: self.configuration.baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)))

    // when
    let _: TestResponse = try await sut.request(target)

    // then
    XCTAssertEqual(self.mockSession.lastRequest?.value(forHTTPHeaderField: "Custom"), "Header")
    XCTAssertEqual(self.mockSession.lastRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
  }

  func test_request_withParameters_encodesCorrectly() async throws {
    // given
    let parameters = ["key": "value"]
    let target = TestTarget(task: .requestParameters(parameters: parameters))
    let response = TestResponse(id: 1, name: "Test")
    let data = try JSONEncoder().encode(response)
    self.mockSession.mockResponse = try (data, XCTUnwrap(HTTPURLResponse(url: self.configuration.baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)))

    // when
    let _: TestResponse = try await sut.request(target)

    // then
    XCTAssertEqual(self.mockSession.lastRequest?.url?.query, "key=value")
  }

  func test_request_withJSONEncodable_setsCorrectBody() async throws {
    // given
    let encodable = TestEncodable(id: 1, name: "Test")
    let target = TestTarget(task: .requestJSONEncodable(encodable))
    let data = try JSONEncoder().encode(encodable)
    self.mockSession.mockResponse = try (data, XCTUnwrap(HTTPURLResponse(url: self.configuration.baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)))

    // when
    let _: TestResponse = try await sut.request(target)

    // then
    let expectedData = try JSONEncoder().encode(encodable)
    XCTAssertEqual(self.mockSession.lastRequest?.httpBody, expectedData)
    XCTAssertEqual(self.mockSession.lastRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
  }

  func test_request_withCompositeBody_setsCorrectBodyAndParameters() async throws {
    // given
    let bodyData = "test".data(using: .utf8)!
    let parameters = ["key": "value"]
    let target = TestTarget(task: .requestCompositeBody(parameters: parameters, body: bodyData))
    let encodable = TestEncodable(id: 1, name: "Test")
    let data = try JSONEncoder().encode(encodable)
    self.mockSession.mockResponse = try (data, XCTUnwrap(HTTPURLResponse(url: self.configuration.baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)))

    // when
    let _: TestResponse = try await sut.request(target)

    // then
    XCTAssertEqual(self.mockSession.lastRequest?.httpBody, bodyData)
    XCTAssertEqual(self.mockSession.lastRequest?.url?.query, "key=value")
  }

  // MARK: - Response Handling Tests

  func test_request_whenSuccess_returnsDecodedResponse() async throws {
    // given
    let response = TestResponse(id: 1, name: "Test")
    let data = try JSONEncoder().encode(response)
    self.mockSession.mockResponse = try (data, XCTUnwrap(HTTPURLResponse(url: self.configuration.baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)))

    // when
    let result: TestResponse = try await sut.request(TestTarget())

    // then
    XCTAssertEqual(result, response)
  }

  func test_request_whenError_throwsNetworkError() async throws {
    // given
    self.mockSession.mockResponse = try (Data(), XCTUnwrap(HTTPURLResponse(url: self.configuration.baseURL, statusCode: 500, httpVersion: nil, headerFields: nil)))

    // when
    do {
      let _: TestResponse = try await sut.request(TestTarget())
      XCTFail("Expected error to be thrown")
    } catch {
      XCTAssertTrue(error is NetworkError)
    }
  }

  func test_request_whenDecodingFails_throwsDecodingError() async throws {
    // given
    let invalidData = "invalid".data(using: .utf8)!
    self.mockSession.mockResponse = try (invalidData, XCTUnwrap(HTTPURLResponse(url: self.configuration.baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)))

    // when
    do {
      let _: TestResponse = try await sut.request(TestTarget())
      XCTFail("Expected error to be thrown")
    } catch {
      XCTAssertTrue(error is NetworkError)
    }
  }

  func test_request_whenError_throw404() async throws {
    // given
    self.mockSession.mockResponse = try (Data(), XCTUnwrap(HTTPURLResponse(url: self.configuration.baseURL, statusCode: 404, httpVersion: nil, headerFields: nil)))

    // when and then
    do {
      let _: TestResponse = try await sut.request(TestTarget())
      XCTFail("Expected error to be thrown")
    } catch let error as NetworkError {
      if case let .httpError(code, _) = error {
        XCTAssertEqual(code, 404)
      } else {
        XCTFail("Expected httpError, got \(error)")
      }
    } catch {
      XCTFail("Expected NetworkError, got \(error)")
    }
  }

  // MARK: - Interceptor Tests

  func test_request_interceptsRequest() async throws {
    // given
    let target = TestTarget()
    let encodable = TestEncodable(id: 1, name: "Test")
    let data = try JSONEncoder().encode(encodable)
    self.mockSession.mockResponse = try (data, XCTUnwrap(HTTPURLResponse(url: self.configuration.baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)))

    // when
    let _: TestResponse = try await sut.request(target)

    // then
    XCTAssertTrue(self.mockInterceptorChain.didInterceptRequest)
  }

  func test_request_interceptsResponse() async throws {
    // given
    let response = TestResponse(id: 1, name: "Test")
    let data = try JSONEncoder().encode(response)
    self.mockSession.mockResponse = try (data, XCTUnwrap(HTTPURLResponse(url: self.configuration.baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)))

    // when
    let _: TestResponse = try await sut.request(TestTarget())

    // then
    XCTAssertTrue(self.mockInterceptorChain.didInterceptResponse)
  }
}

// MARK: - Test Types

private struct TestTarget: Target {
  var path: String = ""
  var method: HTTPMethod = .get
  var task: Task = .requestPlain
  var headers: [String: String] = [:]
}

private struct TestResponse: Codable, Equatable {
  let id: Int
  let name: String
}

private struct TestEncodable: Encodable {
  let id: Int
  let name: String
}

// MARK: - Mock Classes

private class MockNetworkSession: NetworkSessionProtocol {
  var lastRequest: URLRequest?
  var mockResponse: (Data, URLResponse)?

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    self.lastRequest = request
    guard let response = mockResponse else {
      throw NetworkError.invalidResponse
    }
    return response
  }
}

private class MockNetworkInterceptorChain: NetworkInterceptorChain {
  var didInterceptRequest = false
  var didInterceptResponse = false

  init() {
    super.init(interceptors: [])
  }

  override func interceptRequest(_ request: inout URLRequest) {
    self.didInterceptRequest = true
    super.interceptRequest(_: &request)
  }

  override func interceptResponse(response _: URLResponse?, data _: Data?, error _: Error?) {
    self.didInterceptResponse = true
  }
}

private class MockNetworkMonitor: NetworkMonitoring {
  var isConnected: Bool = true
  var connectionType: ConnectionType = .wifi
  var onConnectionChange: ((ConnectionType) -> Void)?
}
