import AtomicLogger
import Foundation
import Networking

struct AppConfig {
  let networkClient: NetworkService
  let logger: LoggerProtocol = {
    #if DEBUG
      return LoggerImpl(label: "GitHubUsers_UAT")
    #else
      return LoggerImpl(label: "GitHubUsers_PROD")
    #endif
  }()

  init() {
    let loggingNetworkInterceptor = LoggingInterceptor(
      logger: logger
    )
    let interceptorChain = NetworkInterceptorChain(interceptors: [loggingNetworkInterceptor])
    let configuration = NetworkServiceImpl.Configuration(
      baseURL: Environment.baseURL,
      defaultHeaders: ["Content-Type": "application/json"]
    )
    self.networkClient = NetworkServiceImpl(
      configuration: configuration,
      session: URLSession.shared,
      interceptorChain: interceptorChain,
      networkMonitor: NetworkMonitor()
    )
  }
}
