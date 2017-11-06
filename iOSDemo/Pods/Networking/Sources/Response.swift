import Foundation

public class Response {
    public var headers: [AnyHashable: Any] {
        return fullResponse.allHeaderFields
    }

    public var statusCode: Int {
        return fullResponse.statusCode
    }

    public let fullResponse: HTTPURLResponse

    init(response: HTTPURLResponse) {
        fullResponse = response
    }
}

public class FailureResponse: Response {
    public let error: NSError

    init(response: HTTPURLResponse, error: NSError) {
        self.error = error

        super.init(response: response)
    }
}

public class JSONResponse: Response {
    let json: JSON

    public var dictionaryBody: [String: Any] {
        return json.dictionary
    }

    public var arrayBody: [[String: Any]] {
        return json.array
    }

    public var data: Data {
        switch json {
        case let .array(value, _):
            return value
        case let .dictionary(value, _):
            return value
        case .none:
            return Data()
        }
    }

    init(json: JSON, response: HTTPURLResponse) {
        self.json = json

        super.init(response: response)
    }
}

public class SuccessJSONResponse: JSONResponse {}

public class FailureJSONResponse: JSONResponse {
    public let error: NSError

    init(json: JSON, response: HTTPURLResponse, error: NSError) {
        self.error = error

        super.init(json: json, response: response)
    }
}

public class SuccessImageResponse: Response {
    public let image: Image

    init(image: Image, response: HTTPURLResponse) {
        self.image = image

        super.init(response: response)
    }
}

public class SuccessDataResponse: Response {
    public let data: Data

    init(data: Data, response: HTTPURLResponse) {
        self.data = data

        super.init(response: response)
    }
}
