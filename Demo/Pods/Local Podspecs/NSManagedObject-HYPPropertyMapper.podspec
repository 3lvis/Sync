Pod::Spec.new do |s|
  s.name = "NSManagedObject-HYPPropertyMapper"
  s.version = "1.7"
  s.summary = "Mapping your Core Data objects with your JSON providing backend has never been this easy"
  s.description = <<-DESC
                   * Mapping your Core Data objects with your JSON providing backend has never been this easy
                   DESC
  s.homepage = "https://github.com/hyperoslo/NSManagedObject-HYPPropertyMapper"
  s.license = {
    :type => 'MIT',
    :file => 'LICENSE.md'
  }
  s.author = { "Hyper Interaktiv" => "teknologi@hyper.no" }
  s.social_media_url = "https://twitter.com/hyperoslo"
  s.platform = :ios, '6.0'
  s.source = {
    :git => 'https://github.com/hyperoslo/NSManagedObject-HYPPropertyMapper.git',
    :tag => s.version.to_s
  }
  s.source_files = 'Source/'
  s.frameworks = 'Foundation'
  s.requires_arc = true
end
