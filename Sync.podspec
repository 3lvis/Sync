Pod::Spec.new do |s|
s.name             = "Sync"
s.version          = "0.6"
s.summary          = "JSON synchronization to Core Data, The Right Way™"
s.description      = <<-DESC
This is a category that eases your every day job of parsing an API and getting it into Core Data.

* Handles operations in safe background threats.
* Thread safe saving (if you're saving in the wrong thread, we'll tell you).
* Diffing of changes, updated, inserted and deleted objects are automatically handled for you.
DESC
s.homepage         = "https://github.com/hyperoslo/Sync"
s.license          = 'MIT'
s.author           = { "Hyper AS" => "iOS@hyper.no" }
s.source           = { :git => "https://github.com/hyperoslo/Sync.git", :tag => s.version.to_s }
s.social_media_url = 'https://twitter.com/hyperoslo'

s.platform     = :ios, '7.0'
s.requires_arc = true

s.source_files = 'Source/**/*'

s.frameworks = 'Foundation', 'CoreData'

s.dependency 'NSManagedObject-HYPPropertyMapper', '~> 2.11'
s.dependency 'NSManagedObject-ANDYMapChanges', '~> 0.7'
s.dependency 'DATAStack', '~> 3.0.2'
s.dependency 'NSDictionary-ANDYSafeValue', '~> 0.3'
end
