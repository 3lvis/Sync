import Foundation

public extension Int {

    /// Categorizes a status code.
    ///
    /// - Returns: The NetworkingStatusCodeType of the status code.
    var statusCodeType: Networking.StatusCodeType {
        switch self {
        case URLError.cancelled.rawValue:
            return .cancelled
        case 100 ..< 200:
            return .informational
        case 200 ..< 300:
            return .successful
        case 300 ..< 400:
            return .redirection
        case 400 ..< 500:
            return .clientError
        case 500 ..< 600:
            return .serverError
        default:
            return .unknown
        }
    }
}

open class Networking {
    static let domain = "com.3lvis.networking"

    struct FakeRequest {
        let response: Any?
        let responseType: ResponseType
        let statusCode: Int
    }

    enum RequestType: String {
        case get = "GET", post = "POST", put = "PUT", delete = "DELETE"
    }

    enum SessionTaskType: String {
        case data, upload, download
    }

    /// Sets the rules to serialize your parameters, also sets the `Content-Type` header.
    ///
    /// - none: No Content-Type header
    /// - json: Serializes your parameters using `NSJSONSerialization` and sets your `Content-Type` to `application/json`.
    /// - formURLEncoded: Serializes your parameters using `Percent-encoding` and sets your `Content-Type` to `application/x-www-form-urlencoded`.
    /// - multipartFormData: Serializes your parameters and parts as multipart and sets your `Content-Type` to `multipart/form-data`.
    /// - custom: Sends your parameters as plain data, sets your `Content-Type` to the value inside `custom`.
    public enum ParameterType {
        case none, json, formURLEncoded, multipartFormData, custom(String)

        func contentType(_ boundary: String) -> String? {
            switch self {
            case .none:
                return nil
            case .json:
                return "application/json"
            case .formURLEncoded:
                return "application/x-www-form-urlencoded"
            case .multipartFormData:
                return "multipart/form-data; boundary=\(boundary)"
            case let .custom(value):
                return value
            }
        }
    }

    enum ResponseType {
        case json
        case data
        case image

        var accept: String? {
            switch self {
            case .json:
                return "application/json"
            default:
                return nil
            }
        }
    }

    /// Categorizes a status code.
    ///
    /// - informational: This class of status code indicates a provisional response, consisting only of the Status-Line and optional headers, and is terminated by an empty line.
    /// - successful: This class of status code indicates that the client's request was successfully received, understood, and accepted.
    /// - redirection: This class of status code indicates that further action needs to be taken by the user agent in order to fulfill the request.
    /// - clientError: The 4xx class of status code is intended for cases in which the client seems to have erred.
    /// - serverError: Response status codes beginning with the digit "5" indicate cases in which the server is aware that it has erred or is incapable of performing the request.
    /// - cancelled: When a request gets cancelled
    /// - unknown: This response status code could be used by Foundation for other types of states.
    public enum StatusCodeType {
        case informational, successful, redirection, clientError, serverError, cancelled, unknown
    }

    fileprivate let baseURL: String
    var fakeRequests = [RequestType: [String: FakeRequest]]()
    var token: String?
    var authorizationHeaderValue: String?
    var authorizationHeaderKey = "Authorization"
    fileprivate var configuration: URLSessionConfiguration
    var cache: NSCache<AnyObject, AnyObject>

    /// Flag used to indicate synchronous request.
    public var isSynchronous = false

    /// Flag used to disable error logging. Useful when want to disable log before release build.
    public var isErrorLoggingEnabled = true

    /// The boundary used for multipart requests.
    let boundary = String(format: "net.3lvis.networking.%08x%08x", arc4random(), arc4random())

    lazy var session: URLSession = {
        URLSession(configuration: self.configuration)
    }()

    /// Base initializer, it creates an instance of `Networking`.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL for HTTP requests under `Networking`.
    ///   - configuration: The URLSessionConfiguration configuration to be used
    ///   - cache: The NSCache to use, it has a built-in default one.
    public init(baseURL: String, configuration: URLSessionConfiguration = .default, cache: NSCache<AnyObject, AnyObject>? = nil) {
        self.baseURL = baseURL
        self.configuration = configuration
        self.cache = cache ?? NSCache()
    }

    /// Authenticates using Basic Authentication, it converts username:password to Base64 then sets the Authorization header to "Basic \(Base64(username:password))".
    ///
    /// - Parameters:
    ///   - username: The username to be used.
    ///   - password: The password to be used.
    public func setAuthorizationHeader(username: String, password: String) {
        let credentialsString = "\(username):\(password)"
        if let credentialsData = credentialsString.data(using: .utf8) {
            let base64Credentials = credentialsData.base64EncodedString(options: [])
            let authString = "Basic \(base64Credentials)"

            authorizationHeaderKey = "Authorization"
            authorizationHeaderValue = authString
        }
    }

    /// Authenticates using a Bearer token, sets the Authorization header to "Bearer \(token)".
    ///
    /// - Parameter token: The token to be used.
    public func setAuthorizationHeader(token: String) {
        self.token = token
    }

    /// Sets the header fields for every HTTP call.
    public var headerFields: [String: String]?

    /// Authenticates using a custom HTTP Authorization header.
    ///
    /// - Parameters:
    ///   - headerKey: Sets this value as the key for the HTTP `Authorization` header
    ///   - headerValue: Sets this value to the HTTP `Authorization` header or to the `headerKey` if you provided that.
    public func setAuthorizationHeader(headerKey: String = "Authorization", headerValue: String) {
        authorizationHeaderKey = headerKey
        authorizationHeaderValue = headerValue
    }

    /// Callback used to intercept requests that return with a 403 or 401 status code.
    public var unauthorizedRequestCallback: (() -> Void)?

    /// Returns a URL by appending the provided path to the Networking's base URL.
    ///
    /// - Parameter path: The path to be appended to the base URL.
    /// - Returns: A URL generated after appending the path to the base URL.
    /// - Throws: An error if the URL couldn't be created.
    public func composedURL(with path: String) throws -> URL {
        let encodedPath = path.encodeUTF8() ?? path
        guard let url = URL(string: baseURL + encodedPath) else {
            throw NSError(domain: Networking.domain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Couldn't create a url using baseURL: \(baseURL) and encodedPath: \(encodedPath)"])
        }
        return url
    }

    /// Returns the URL used to store a resource for a certain path. Useful to find where a download image is located.
    ///
    /// - Parameters:
    ///   - path: The path used to download the resource.
    ///   - cacheName: The alias to be used for storing the resource, if a cache name is provided, this will be used instead of the path.
    /// - Returns: A URL where a resource has been stored.
    /// - Throws: An error if the URL couldn't be created.
    public func destinationURL(for path: String, cacheName: String? = nil) throws -> URL {
        let normalizedCacheName = cacheName?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        var resourcesPath: String
        if let normalizedCacheName = normalizedCacheName {
            resourcesPath = normalizedCacheName
        } else {
            let url = try composedURL(with: path)
            resourcesPath = url.absoluteString
        }

        let normalizedResourcesPath = resourcesPath.replacingOccurrences(of: "/", with: "-")
        let folderPath = Networking.domain
        let finalPath = "\(folderPath)/\(normalizedResourcesPath)"

        if let url = URL(string: finalPath) {
            #if os(tvOS)
                let directory = FileManager.SearchPathDirectory.cachesDirectory
            #else
                let directory = TestCheck.isTesting ? FileManager.SearchPathDirectory.cachesDirectory : FileManager.SearchPathDirectory.documentDirectory
            #endif
            if let cachesURL = FileManager.default.urls(for: directory, in: .userDomainMask).first {
                try (cachesURL as NSURL).setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
                let folderURL = cachesURL.appendingPathComponent(URL(string: folderPath)!.absoluteString)

                if FileManager.default.exists(at: folderURL) == false {
                    try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: false, attributes: nil)
                }

                let destinationURL = cachesURL.appendingPathComponent(url.absoluteString)

                return destinationURL
            } else {
                throw NSError(domain: Networking.domain, code: 9999, userInfo: [NSLocalizedDescriptionKey: "Couldn't normalize url"])
            }
        } else {
            throw NSError(domain: Networking.domain, code: 9999, userInfo: [NSLocalizedDescriptionKey: "Couldn't create a url using replacedPath: \(finalPath)"])
        }
    }

    /// Splits a url in base url and relative path.
    ///
    /// - Parameter path: The full url to be splitted.
    /// - Returns: A base url and a relative path.
    public static func splitBaseURLAndRelativePath(for path: String) -> (baseURL: String, relativePath: String) {
        guard let encodedPath = path.encodeUTF8() else { fatalError("Couldn't encode path to UTF8: \(path)") }
        guard let url = URL(string: encodedPath) else { fatalError("Path \(encodedPath) can't be converted to url") }
        guard let baseURLWithDash = URL(string: "/", relativeTo: url)?.absoluteURL.absoluteString else { fatalError("Can't find absolute url of url: \(url)") }
        let index = baseURLWithDash.index(before: baseURLWithDash.endIndex)
        let baseURL = String(baseURLWithDash[..<index])
        let relativePath = path.replacingOccurrences(of: baseURL, with: "")

        return (baseURL, relativePath)
    }

    /// Cancels the request that matches the requestID.
    ///
    /// - Parameter requestID: The ID of the request to be cancelled.
    public func cancel(_ requestID: String) {
        let semaphore = DispatchSemaphore(value: 0)
        session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            var tasks = [URLSessionTask]()
            tasks.append(contentsOf: dataTasks as [URLSessionTask])
            tasks.append(contentsOf: uploadTasks as [URLSessionTask])
            tasks.append(contentsOf: downloadTasks as [URLSessionTask])

            for task in tasks {
                if task.taskDescription == requestID {
                    task.cancel()
                    break
                }
            }

            semaphore.signal()
        }

        _ = semaphore.wait(timeout: DispatchTime.now() + 60.0)
    }

    /// Cancels all the current requests.
    public func cancelAllRequests() {
        let semaphore = DispatchSemaphore(value: 0)
        session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            for sessionTask in dataTasks {
                sessionTask.cancel()
            }
            for sessionTask in downloadTasks {
                sessionTask.cancel()
            }
            for sessionTask in uploadTasks {
                sessionTask.cancel()
            }

            semaphore.signal()
        }

        _ = semaphore.wait(timeout: DispatchTime.now() + 60.0)
    }

    /// Deletes the downloaded/cached files.
    public static func deleteCachedFiles() {
        #if os(tvOS)
            let directory = FileManager.SearchPathDirectory.cachesDirectory
        #else
            let directory = TestCheck.isTesting ? FileManager.SearchPathDirectory.cachesDirectory : FileManager.SearchPathDirectory.documentDirectory
        #endif
        if let cachesURL = FileManager.default.urls(for: directory, in: .userDomainMask).first {
            let folderURL = cachesURL.appendingPathComponent(URL(string: Networking.domain)!.absoluteString)

            if FileManager.default.exists(at: folderURL) {
                _ = try? FileManager.default.remove(at: folderURL)
            }
        }
    }

    /// Removes the stored credentials and cached data.
    public func reset() {
        cache.removeAllObjects()
        fakeRequests.removeAll()
        token = nil
        headerFields = nil
        authorizationHeaderKey = "Authorization"
        authorizationHeaderValue = nil

        Networking.deleteCachedFiles()
    }
}
