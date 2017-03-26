import CoreData

/// The inflection type used to export the NSManagedObject as JSON.
///
/// - snakeCase: Uses snake_case notation.
/// - camelCase: Uses camelCase notation.
public enum InflectionType {
    case snakeCase
    case camelCase
}

/// The relationship type used to export the NSManagedObject as JSON.
///
/// - array: Normal JSON representation of relationships.
/// - nested: Uses Ruby on Rails's accepts_nested_attributes_for notation to represent relationships.
/// - none: Skip all relationships.
public enum RelationshipType {
    case array
    case nested
    case none
}

public struct ExportOptions {
    public var inflectionType: InflectionType
    public var relationshipType: RelationshipType
    public var dateFormatter: DateFormatter

    public init() {
        self.inflectionType = .snakeCase
        self.relationshipType = .array
        self.dateFormatter = .default()
    }


    /// Convenience initalizer for a camel cased export.
    public static var camelCase: ExportOptions {
        var exportOptions = ExportOptions()
        exportOptions.inflectionType = .camelCase

        return exportOptions
    }

    /// Convenience initalizer for exporting without relationships.
    public static var excludedRelationships: ExportOptions {
        var exportOptions = ExportOptions()
        exportOptions.relationshipType = .none

        return exportOptions
    }
}

public extension NSManagedObject {
    
    /// Fills the `NSManagedObject` with the contents of the dictionary using a convention-over-configuration paradigm mapping the Core Data attributes to their conterparts in JSON using snake_case.
    ///
    /// - Returns: The JSON dictionary to be used to fill the values of your `NSManagedObject`.
    public func export() -> [String: Any] {
        return hyp_dictionary(using: .array)
    }

    /// Fills the `NSManagedObject` with the contents of the dictionary using a convention-over-configuration paradigm mapping the Core Data attributes to their conterparts in JSON using snake_case.
    ///
    /// - Parameter options: The options used to export the JSON, such as inflection type, relationship type and date formatting.
    /// - Returns: The JSON dictionary to be used to fill the values of your `NSManagedObject`.
    public func export(using options: ExportOptions) -> [String: Any] {
        let inflectionType: SyncPropertyMapperInflectionType
        switch options.inflectionType {
        case .camelCase:
            inflectionType = .camelCase
        case .snakeCase:
            inflectionType = .snakeCase
        }

        let relationshipType: SyncPropertyMapperRelationshipType
        switch options.relationshipType {
        case .array:
            relationshipType = .array
        case .nested:
            relationshipType = .nested
        case .none:
            relationshipType = .none
        }

        return hyp_dictionary(with: options.dateFormatter, using: inflectionType, andRelationshipType: relationshipType)
    }
}

extension DateFormatter {
    class func `default`() -> DateFormatter {
        return ExportStorage.shared.formatter
    }
}

class ExportStorage {
    lazy var formatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"

        return formatter
    }()

    static let shared: ExportStorage = {
        let instance = ExportStorage()

        return instance
    }()
}
