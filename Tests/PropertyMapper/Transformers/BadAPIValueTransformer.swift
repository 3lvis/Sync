import Foundation

class BadAPIValueTransformer : ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSString.self as AnyClass
    }

    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    // Used to transform before inserting into Core Data using `hyp_fill(with:)
    override func transformedValue(_ value: Any?) -> Any? {
        guard let valueToTransform = value as? Array<String> else {
            return value
        }

        return valueToTransform.first!
    }

    // Used to transform before exporting into JSON using `export()`
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let stringValue = value as? String else { return value }

        return [stringValue]
    }
}
