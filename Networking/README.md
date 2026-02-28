# Networking

A modular, extensible, and testable Swift networking library for iOS, designed to simplify API requests, response handling, error management, and network monitoring.

## Features

- **Type-safe API requests** using protocols and generics
- **Customizable request/response interception** (logging, authentication, etc.)
- **Network connectivity monitoring**
- **Comprehensive error handling**
- **Async/await support**
- **Easily mockable for unit testing**
- **iOS 16+ support via Swift Package Manager**

---

## Installation

Add the package to your `Package.swift` dependencies:

```swift
.package(path: "../Networking")
```

Or use Xcode's Swift Package Manager integration.

---

## Usage

### 1. Define Your API Endpoints

Conform to the `Target` protocol to describe your endpoints:

```swift
import Networking

struct MyEndpoint: Target {
    var path: String { "/users" }
    var method: HTTPMethod { .get }
    var task: Task { .requestPlain }
    var headers: [String: String] { [:] }
}
```

### 2. Create a Network Service

```swift
import Networking

let config = NetworkServiceImpl.Configuration(
    baseURL: URL(string: "https://api.example.com")!,
    timeoutInterval: 30,
    defaultHeaders: ["Content-Type": "application/json"]
)

let service = NetworkService(
    configuration: config,
    session: URLSession.shared, // or a custom NetworkSessionProtocol
    interceptorChain: NetworkInterceptorChain(interceptors: []),
    networkMonitor: NetworkMonitor()
)
```

### 3. Make a Request

```swift
struct User: Decodable { let id: Int; let name: String }

let endpoint = MyEndpoint()
let user: User = try await service.request(endpoint)
```

---

## API Reference

### Target Protocol

```swift
public protocol Target {
    var path: String { get }
    var method: HTTPMethod { get }
    var task: Task { get }
    var headers: [String: String] { get }
}
```

- `HTTPMethod`: `.get`, `.post`, `.put`, `.delete`, `.patch`
- `Task`: `.requestPlain`, `.requestParameters([:])`, `.requestBody(Data)`, `.requestJSONEncodable(Encodable)`, `.requestCompositeBody(parameters: [String: Any], body: Data)`

### NetworkService

- `request<T: Decodable>(_ target: Target) async throws -> T`

### NetworkSessionProtocol

Abstraction for network sessions (default: `URLSession`):

```swift
public protocol NetworkSessionProtocol: AnyObject {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}
```

### NetworkInterceptor & NetworkInterceptorChain

- Implement `NetworkInterceptor` to intercept/modify requests and responses.
- Add interceptors to `NetworkInterceptorChain`.

```swift
public protocol NetworkInterceptor {
    func intercept(request: inout URLRequest)
    func intercept(response: URLResponse?, data: Data?, error: Error?)
}
```

### NetworkMonitor

Monitor network connectivity and type:

```swift
public protocol NetworkMonitoring {
    var isConnected: Bool { get }
    var connectionType: ConnectionType { get }
    var onConnectionChange: ((ConnectionType) -> Void)? { get set }
}
```

---

## Error Handling

All errors conform to `NetworkError`:

- `.invalidURL`
- `.invalidResponse`
- `.httpError(statusCode: Int, data: Data?)`
- `.decodingError(Error)`
- `.networkError(Error)`
- `.unauthorized`
- `.timeout`
- `.cancelled`
- `.sslPinningFailed`
- `.noConnection`
- `.unknown`

---

## Testing

- All components are protocol-based and easily mockable.
- You can inject mock sessions, interceptors, and monitors for unit testing.

---

## License

This package is licensed under the terms of the license included in the `LICENSE` file.  