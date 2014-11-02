Pod::Spec.new do |s|
s.name             = "NSManagedObject-ANDYMapChanges"
s.version          = "0.3"
s.summary          = "Maps inserts, updates and deletions using JSON"
s.description      = <<-DESC
Maps inserts, updates and deletions using JSON

Returns every insert and update in a block,
handles deletions internally.
DESC
s.homepage         = "https://github.com/nselvis/NSManagedObject-ANDYMapChanges"
s.license          = 'MIT'
s.author           = { "Elvis Nuñez" => "elvisnunez@me.com" }
s.source           = { :git => "https://github.com/nselvis/NSManagedObject-ANDYMapChanges.git", :tag => s.version.to_s }
s.social_media_url = 'https://twitter.com/nselvis'

s.platform     = :ios, '7.0'
s.requires_arc = true

s.source_files = 'Source/**/*'

s.frameworks = 'Foundation'
end
