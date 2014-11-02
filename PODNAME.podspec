Pod::Spec.new do |s|
s.name             = "NSManagedObject-ANDYNetworking"
s.version          = "0.5"
s.summary          = "A cape, a sword and networking superpowers for your NSManagedObject!"
s.description      = <<-DESC
This is a category that eases your everyday job of parsing an API and getting it into CoreData.

* Handles operations in safe background threats.
* Thread safe saving (if you're saving in the wrong thread, we'll tell you).
* Diffing of changes, updated, inserted and deleted objects are automatically handled for you.
DESC
s.homepage         = "https://github.com/nselvis/NSManagedObject-ANDYNetworking"
s.license          = 'MIT'
s.author           = { "Elvis Nuñez" => "elvisnunez@me.com" }
s.source           = { :git => "https://github.com/nselvis/NSManagedObject-ANDYNetworking.git", :tag => s.version.to_s }
s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

s.platform     = :ios, '7.0'
s.requires_arc = true

s.source_files = 'Source/**/*'

# s.frameworks = 'Foundation', 'CoreData'
# s.dependency 'NSManagedObject+HYPPropertyMapper', 'NSManagedObject+ANDYMapChanges', 'ANDYDataManager'
end
