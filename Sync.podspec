Pod::Spec.new do |s|
s.name             = "Sync"
s.version          = "1.7.2"
s.summary          = "Modern Swift JSON synchronization to Core Data"
s.description      = <<-DESC
**Sync** eases your everyday job of parsing a `JSON` response and getting it into Core Data. It uses a convention-over-configuration paradigm to facilitate your workflow.

* Automatic mapping of CamelCase or snake_case JSON into Core Data
* Handles operations in safe background threads
* Thread-safe saving, we handle retrieving and storing objects in the right threads
* Diffing of changes, updated, inserted and deleted objects (which are automatically purged for you)
* Auto-mapping of relationships (one-to-one, one-to-many and many-to-many)
* Smart-updates, only updates your `NSManagedObject`s if the server values are different (useful when using `NSFetchedResultsController` delegates)
* Uniquing, Core Data does this based on `objectID`s, we use your primary key (such as `id`) for this
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

s.dependency 'DATAFilter', '~> 0.10.0'
s.dependency 'DATAStack', '~> 5.2.1'
s.dependency 'NSDictionary-ANDYSafeValue', '~> 0.3.1'
s.dependency 'NSEntityDescription-SYNCPrimaryKey', '~> 1.2.0'
s.dependency 'NSManagedObject-HYPPropertyMapper', '~> 3.6.6'
end
