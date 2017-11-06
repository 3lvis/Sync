import Foundation

/// The type of the form data part.
///
/// - data: Plain data, it uses "application/octet-stream" as the Content-Type.
/// - png: PNG image, it uses "image/png" as the Content-Type.
/// - jpg: JPG image, it uses "image/jpeg" as the Content-Type.
/// - custom: Sends your parameters as plain data, sets your `Content-Type` to the value inside `custom`.
public enum FormDataPartType {
    case data
    case png
    case jpg
    case custom(String)

    var contentType: String {
        switch self {
        case .data:
            return "application/octet-stream"
        case .png:
            return "image/png"
        case .jpg:
            return "image/jpeg"
        case let .custom(value):
            return value
        }
    }
}

/// The form data part.
public struct FormDataPart {
    fileprivate let data: Data
    fileprivate let parameterName: String
    fileprivate let filename: String?
    fileprivate let type: FormDataPartType
    var boundary: String = ""

    var formData: Data {
        var body = ""
        body += "--\(boundary)\r\n"
        body += "Content-Disposition: form-data; "
        body += "name=\"\(parameterName)\""
        if let filename = filename {
            body += "; filename=\"\(filename)\""
        }
        body += "\r\n"
        body += "Content-Type: \(type.contentType)\r\n\r\n"

        var bodyData = Data()
        bodyData.append(body.data(using: .utf8)!)
        bodyData.append(data)
        bodyData.append("\r\n".data(using: .utf8)!)

        return bodyData as Data
    }

    public init(type: FormDataPartType = .data, data: Data, parameterName: String, filename: String? = nil) {
        self.type = type
        self.data = data
        self.parameterName = parameterName
        self.filename = filename
    }
}
