import Foundation
import OSLog

public final class NetworkServiceImpl {
  public struct Configuration {
    public let baseURL: URL
    public let timeoutInterval: TimeInterval
    public let defaultHeaders: [String: String]

    public init(baseURL: URL, timeoutInterval: TimeInterval = 30, defaultHeaders: [String: String] = [:]) {
      self.baseURL = baseURL
      self.timeoutInterval = timeoutInterval
      self.defaultHeaders = defaultHeaders
    }
  }

  public let configuration: Configuration
  public let session: NetworkSessionProtocol
  public let interceptorChain: NetworkInterceptorChain
  public let networkMonitor: NetworkMonitoring

  public init(
    configuration: Configuration,
    session: NetworkSessionProtocol,
    interceptorChain: NetworkInterceptorChain,
    networkMonitor: NetworkMonitoring
  ) {
    self.configuration = configuration
    self.session = session
    self.interceptorChain = interceptorChain
    self.networkMonitor = networkMonitor
  }
}

extension NetworkServiceImpl: NetworkService {
  public func request<T: Decodable>(_ target: Target) async throws -> T {
    guard self.networkMonitor.isConnected else {
      throw NetworkError.noConnection
    }

    var request = try buildRequest(from: target)
    self.interceptorChain.interceptRequest(&request)

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw NetworkError.invalidResponse
    }

    guard (200 ... 299).contains(httpResponse.statusCode) else {
      throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
    }

    self.interceptorChain.interceptResponse(response: response, data: data, error: nil)

    do {
      return try JSONDecoder().decode(T.self, from: data)
    } catch {
      self.interceptorChain.interceptResponse(response: nil, data: nil, error: error)
      throw NetworkError.decodingError(error)
    }
  }

  private func buildRequest(from target: Target) throws -> URLRequest {
    let url = self.configuration.baseURL.appendingPathComponent(target.path)
    var request = URLRequest(url: url)
    request.httpMethod = target.method.rawValue
    request.timeoutInterval = self.configuration.timeoutInterval

    // Add default headers
    self.configuration.defaultHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }

    // Add target headers
    target.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

    // Handle task
    switch target.task {
    case .requestPlain:
      break
    case let .requestParameters(parameters):
      var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
      components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
      request.url = components?.url
    case let .requestBody(data):
      request.httpBody = data
    case let .requestJSONEncodable(encodable):
      request.httpBody = try JSONEncoder().encode(encodable)
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    case let .requestCompositeBody(parameters: parameters, body: data):
      var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
      components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
      request.url = components?.url
      request.httpBody = data
    }

    return request
  }
}
