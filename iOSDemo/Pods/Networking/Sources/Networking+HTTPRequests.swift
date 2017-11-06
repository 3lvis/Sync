import Foundation

public extension Networking {

    /// GET request to the specified path.
    ///
    /// - Parameters:
    ///   - path: The path for the GET request.
    ///   - parameters: The parameters to be used, they will be serialized using Percent-encoding and appended to the URL.
    ///   - completion: The result of the operation, it's an enum with two cases: success and failure.
    /// - Returns: The request identifier.
    @discardableResult
    public func get(_ path: String, parameters: Any? = nil, completion: @escaping (_ result: JSONResult) -> Void) -> String {
        let parameterType: ParameterType = parameters != nil ? .formURLEncoded : .none

        return handleJSONRequest(.get, path: path, parameterType: parameterType, parameters: parameters, responseType: .json, completion: completion)
    }

    /// Registers a fake GET request for the specified path. After registering this, every GET request to the path, will return the registered response.
    ///
    /// - Parameters:
    ///   - path: The path for the faked GET request.
    ///   - response: An `Any` that will be returned when a GET request is made to the specified path.
    ///   - statusCode: By default it's 200, if you provide any status code that is between 200 and 299 the response object will be returned, otherwise we will return an error containig the provided status code.
    public func fakeGET(_ path: String, response: Any?, statusCode: Int = 200) {
        registerFake(requestType: .get, path: path, response: response, responseType: .json, statusCode: statusCode)
    }

    /// Registers a fake GET request for the specified path using the contents of a file. After registering this, every GET request to the path, will return the contents of the registered file.
    ///
    /// - Parameters:
    ///   - path: The path for the faked GET request.
    ///   - fileName: The name of the file, whose contents will be registered as a reponse.
    ///   - bundle: The Bundle where the file is located.
    public func fakeGET(_ path: String, fileName: String, bundle: Bundle = Bundle.main) {
        registerFake(requestType: .get, path: path, fileName: fileName, bundle: bundle)
    }

    /// Cancels the GET request for the specified path. This causes the request to complete with error code URLError.cancelled.
    ///
    /// - Parameter path: The path for the cancelled GET request
    public func cancelGET(_ path: String) {
        let url = try! composedURL(with: path)
        cancelRequest(.data, requestType: .get, url: url)
    }
}

public extension Networking {

    /// PUT request to the specified path, using the provided parameters.
    ///
    /// - Parameters:
    ///   - path: The path for the PUT request.
    ///   - parameterType: The parameters type to be used, by default is JSON.
    ///   - parameters: The parameters to be used, they will be serialized using the ParameterType, by default this is JSON.
    ///   - completion: The result of the operation, it's an enum with two cases: success and failure.
    /// - Returns: The request identifier.
    @discardableResult
    public func put(_ path: String, parameterType: ParameterType = .json, parameters: Any? = nil, completion: @escaping (_ result: JSONResult) -> Void) -> String {
        return handleJSONRequest(.put, path: path, parameterType: parameterType, parameters: parameters, responseType: .json, completion: completion)
    }

    /// Registers a fake PUT request for the specified path. After registering this, every PUT request to the path, will return the registered response.
    ///
    /// - Parameters:
    ///   - path: The path for the faked PUT request.
    ///   - response: An `Any` that will be returned when a PUT request is made to the specified path.
    ///   - statusCode: By default it's 200, if you provide any status code that is between 200 and 299 the response object will be returned, otherwise we will return an error containig the provided status code.
    public func fakePUT(_ path: String, response: Any?, statusCode: Int = 200) {
        registerFake(requestType: .put, path: path, response: response, responseType: .json, statusCode: statusCode)
    }

    /// Registers a fake PUT request to the specified path using the contents of a file. After registering this, every PUT request to the path, will return the contents of the registered file.
    ///
    /// - Parameters:
    ///   - path: The path for the faked PUT request.
    ///   - fileName: The name of the file, whose contents will be registered as a reponse.
    ///   - bundle: The Bundle where the file is located.
    public func fakePUT(_ path: String, fileName: String, bundle: Bundle = Bundle.main) {
        registerFake(requestType: .put, path: path, fileName: fileName, bundle: bundle)
    }

    /// Cancels the PUT request for the specified path. This causes the request to complete with error code URLError.cancelled.
    ///
    /// - Parameter path: The path for the cancelled PUT request.
    public func cancelPUT(_ path: String) {
        let url = try! composedURL(with: path)
        cancelRequest(.data, requestType: .put, url: url)
    }
}

public extension Networking {

    /// POST request to the specified path, using the provided parameters.
    ///
    /// - Parameters:
    ///   - path: The path for the POST request.
    ///   - parameterType: The parameters type to be used, by default is JSON.
    ///   - parameters: The parameters to be used, they will be serialized using the ParameterType, by default this is JSON.
    ///   - completion: The result of the operation, it's an enum with two cases: success and failure.
    /// - Returns: The request identifier.
    @discardableResult
    public func post(_ path: String, parameterType: ParameterType = .json, parameters: Any? = nil, completion: @escaping (_ result: JSONResult) -> Void) -> String {
        return handleJSONRequest(.post, path: path, parameterType: parameterType, parameters: parameters, responseType: .json, completion: completion)
    }

    /// POST request to the specified path, using the provided parameters.
    ///
    /// - Parameters:
    ///   - path: The path for the POST request.
    ///   - parameters: The parameters to be used, they will be serialized using the ParameterType, by default this is JSON.
    ///   - parts: The list of form data parts that will be sent in the request.
    ///   - completion: A closure that gets called when the POST request is completed, it contains a `JSON` object and an `NSError`.
    /// - Returns: The request identifier.
    @discardableResult
    public func post(_ path: String, parameters: Any? = nil, parts: [FormDataPart], completion: @escaping (_ result: JSONResult) -> Void) -> String {
        return handleJSONRequest(.post, path: path, parameterType: .multipartFormData, parameters: parameters, parts: parts, responseType: .json, completion: completion)
    }

    /// Registers a fake POST request for the specified path. After registering this, every POST request to the path, will return the registered response.
    ///
    /// - Parameters:
    ///   - path: The path for the faked POST request.
    ///   - response: An `Any` that will be returned when a POST request is made to the specified path.
    ///   - statusCode: By default it's 200, if you provide any status code that is between 200 and 299 the response object will be returned, otherwise we will return an error containig the provided status code.
    public func fakePOST(_ path: String, response: Any?, statusCode: Int = 200) {
        registerFake(requestType: .post, path: path, response: response, responseType: .json, statusCode: statusCode)
    }

    /// Registers a fake POST request to the specified path using the contents of a file. After registering this, every POST request to the path, will return the contents of the registered file.
    ///
    /// - Parameters:
    ///   - path: The path for the faked POST request.
    ///   - fileName: The name of the file, whose contents will be registered as a reponse.
    ///   - bundle: The Bundle where the file is located.
    public func fakePOST(_ path: String, fileName: String, bundle: Bundle = Bundle.main) {
        registerFake(requestType: .post, path: path, fileName: fileName, bundle: bundle)
    }

    /// Cancels the POST request for the specified path. This causes the request to complete with error code URLError.cancelled.
    ///
    /// - Parameter path: The path for the cancelled POST request.
    public func cancelPOST(_ path: String) {
        let url = try! composedURL(with: path)
        cancelRequest(.data, requestType: .post, url: url)
    }
}

public extension Networking {

    /// DELETE request to the specified path, using the provided parameters.
    ///
    /// - Parameters:
    ///   - path: The path for the DELETE request.
    ///   - parameters: The parameters to be used, they will be serialized using Percent-encoding and appended to the URL.
    ///   - completion: The result of the operation, it's an enum with two cases: success and failure.
    /// - Returns: The request identifier.
    @discardableResult
    public func delete(_ path: String, parameters: Any? = nil, completion: @escaping (_ result: JSONResult) -> Void) -> String {
        let parameterType: ParameterType = parameters != nil ? .formURLEncoded : .none
        return handleJSONRequest(.delete, path: path, parameterType: parameterType, parameters: parameters, responseType: .json, completion: completion)
    }

    /// Registers a fake DELETE request for the specified path. After registering this, every DELETE request to the path, will return the registered response.
    ///
    /// - Parameters:
    ///   - path: The path for the faked DELETE request.
    ///   - response: An `Any` that will be returned when a DELETE request is made to the specified path.
    ///   - statusCode: By default it's 200, if you provide any status code that is between 200 and 299 the response object will be returned, otherwise we will return an error containig the provided status code.
    public func fakeDELETE(_ path: String, response: Any?, statusCode: Int = 200) {
        registerFake(requestType: .delete, path: path, response: response, responseType: .json, statusCode: statusCode)
    }

    /// Registers a fake DELETE request to the specified path using the contents of a file. After registering this, every DELETE request to the path, will return the contents of the registered file.
    ///
    /// - Parameters:
    ///   - path: The path for the faked DELETE request.
    ///   - fileName: The name of the file, whose contents will be registered as a reponse.
    ///   - bundle: The Bundle where the file is located.
    public func fakeDELETE(_ path: String, fileName: String, bundle: Bundle = Bundle.main) {
        registerFake(requestType: .delete, path: path, fileName: fileName, bundle: bundle)
    }

    /// Cancels the DELETE request for the specified path. This causes the request to complete with error code URLError.cancelled.
    ///
    /// - Parameter path: The path for the cancelled DELETE request.
    public func cancelDELETE(_ path: String) {
        let url = try! composedURL(with: path)
        cancelRequest(.data, requestType: .delete, url: url)
    }
}

public extension Networking {

    /// Retrieves an image from the cache or from the filesystem.
    ///
    /// - Parameters:
    ///   - path: The path where the image is located.
    ///   - cacheName: The cache name used to identify the downloaded image, by default the path is used.
    /// - Returns: The cached image.
    public func imageFromCache(_ path: String, cacheName: String? = nil) -> Image? {
        let object = objectFromCache(for: path, cacheName: cacheName, responseType: .image)

        return object as? Image
    }

    /// Downloads an image using the specified path.
    ///
    /// - Parameters:
    ///   - path: The path where the image is located.
    ///   - cacheName: The cache name used to identify the downloaded image, by default the path is used.
    ///   - completion: The result of the operation, it's an enum with two cases: success and failure.
    /// - Returns: The request identifier.
    @discardableResult
    public func downloadImage(_ path: String, cacheName: String? = nil, completion: @escaping (_ result: ImageResult) -> Void) -> String {
        return handleImageRequest(.get, path: path, cacheName: cacheName, responseType: .image, completion: completion)
    }

    /// Cancels the image download request for the specified path. This causes the request to complete with error code URLError.cancelled.
    ///
    /// - Parameter path: The path for the cancelled image download request.
    public func cancelImageDownload(_ path: String) {
        let url = try! composedURL(with: path)
        cancelRequest(.data, requestType: .get, url: url)
    }

    /// Registers a fake download image request with an image. After registering this, every download request to the path, will return the registered image.
    ///
    /// - Parameters:
    ///   - path: The path for the faked image download request.
    ///   - image: An image that will be returned when there's a request to the registered path.
    ///   - statusCode: The status code to be used when faking the request.
    public func fakeImageDownload(_ path: String, image: Image?, statusCode: Int = 200) {
        registerFake(requestType: .get, path: path, response: image, responseType: .image, statusCode: statusCode)
    }

    /// Downloads data from a URL, caching the result.
    ///
    /// - Parameters:
    ///   - path: The path used to download the resource.
    ///   - cacheName: The cache name used to identify the downloaded data, by default the path is used.
    ///   - completion: A closure that gets called when the download request is completed, it contains  a `data` object and an `NSError`.
    @discardableResult
    public func downloadData(_ path: String, cacheName: String? = nil, completion: @escaping (_ result: DataResult) -> Void) -> String {
        return handleDataRequest(.get, path: path, cacheName: cacheName, responseType: .data, completion: completion)
    }

    /// Retrieves data from the cache or from the filesystem.
    ///
    /// - Parameters:
    ///   - path: The path where the image is located.
    ///   - cacheName: The cache name used to identify the downloaded data, by default the path is used.
    /// - Returns: The cached data.
    public func dataFromCache(_ path: String, cacheName: String? = nil) -> Data? {
        let object = objectFromCache(for: path, cacheName: cacheName, responseType: .data)

        return object as? Data
    }
}
