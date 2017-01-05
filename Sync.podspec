Pod::Spec.new do |s|
s.name             = "Sync"
s.version          = "2.7.0"
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
s.homepage         = "https://github.com/SyncDB/Sync"
s.license          = 'MIT'
s.author           = { "SyncDB" => "syncdb.contact@gmail.com" }
s.source           = { :git => "https://github.com/SyncDB/Sync.git", :tag => s.version.to_s }
s.social_media_url = 'https://twitter.com/Sync_DB'

s.ios.deployment_target = '9.0'
s.osx.deployment_target = '10.11'
s.watchos.deployment_target = '2.0'
s.tvos.deployment_target = '9.0'
s.requires_arc = true
s.source_files = 'Source/**/*'

s.frameworks = 'Foundation', 'CoreData'

s.dependency 'DATAStack', '~> 7.0.1'
s.dependency 'SYNCPropertyMapper', '~> 5.2.0'
end
