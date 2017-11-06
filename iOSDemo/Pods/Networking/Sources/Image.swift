#if os(OSX)
    import AppKit.NSImage
    public typealias Image = NSImage
#else
    import UIKit.UIImage
    public typealias Image = UIImage
#endif

extension Image {

    static func find(named name: String, inBundle bundle: Bundle) -> Image {
        #if os(OSX)
            return bundle.image(forResource: NSImage.Name(rawValue: name))!
        #elseif os(watchOS)
            return UIImage(named: name)!
        #else
            return UIImage(named: name, in: bundle, compatibleWith: nil)!
        #endif
    }

    #if os(OSX)

        func data(_ type: NSBitmapImageRep.FileType) -> Data? {
            let imageData = tiffRepresentation!
            let bitmapImageRep = NSBitmapImageRep(data: imageData)!
            let data = bitmapImageRep.representation(using: type, properties: [NSBitmapImageRep.PropertyKey: Any]())
            return data
        }
    #endif

    func pngData() -> Data? {
        #if os(OSX)
            return data(.png)
        #else
            return UIImagePNGRepresentation(self)
        #endif
    }

    func jpgData() -> Data? {
        #if os(OSX)
            return data(.jpeg)
        #else
            return UIImageJPEGRepresentation(self, 1)
        #endif
    }
}
