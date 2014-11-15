Pod::Spec.new do |s|
s.name             = "Kipu"
s.version          = "0.2"
s.summary          = "A cape, a sword and networking superpowers for your Core Data models"
s.description      = <<-DESC
This is a category that eases your every day job of parsing an API and getting it into CoreData.

* Handles operations in safe background threats.
* Thread safe saving (if you're saving in the wrong thread, we'll tell you).
* Diffing of changes, updated, inserted and deleted objects are automatically handled for you.
DESC
s.homepage         = "https://github.com/nselvis/Kipu"
s.license          = 'MIT'
s.author           = { "Elvis Nuñez" => "elvisnunez@me.com" }
s.source           = { :git => "https://github.com/nselvis/Kipu.git", :tag => s.version.to_s }
s.social_media_url = 'https://twitter.com/nselvis'

s.platform     = :ios, '7.0'
s.requires_arc = true

s.source_files = 'Source/**/*'

s.frameworks = 'Foundation', 'CoreData'

s.dependency 'NSManagedObject-HYPPropertyMapper'
s.dependency 'NSManagedObject-ANDYMapChanges'
s.dependency 'ANDYDataManager'
s.dependency 'NSDictionary-ANDYSafeValue'
end
