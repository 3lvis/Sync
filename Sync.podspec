Pod::Spec.new do |s|
s.name             = "Sync"
s.version          = "1.6.5"
s.summary          = "Modern JSON synchronization to Core Data"
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

s.ios.deployment_target = '8.0'
s.osx.deployment_target = '10.9'
s.watchos.deployment_target = '2.0'
s.tvos.deployment_target = '9.0'
s.requires_arc = true
s.source_files = 'Source/**/*'

s.frameworks = 'Foundation', 'CoreData'

s.dependency 'DATAFilter', '~> 0.9.1'
s.dependency 'DATAStack', '~> 4.3.0'
s.dependency 'NSDictionary-ANDYSafeValue', '~> 0.3.1'
s.dependency 'NSEntityDescription-SYNCPrimaryKey', '~> 0.1.2'
s.dependency 'NSManagedObject-HYPPropertyMapper', '~> 3.6.0'
end
