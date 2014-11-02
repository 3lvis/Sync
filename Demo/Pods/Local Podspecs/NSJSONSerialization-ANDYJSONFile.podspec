Pod::Spec.new do |s|
  s.name = "NSJSONSerialization-ANDYJSONFile"
  s.version = "1.0"
  s.summary = "Get an array or dictionary from a .json file"
  s.description = <<-DESC
                   * Get an array or dictionary from a .json file
                   DESC
  s.homepage = "https://github.com/NSElvis/NSJSONSerialization-ANDYJSONFile"
  s.license = {
    :type => 'MIT',
    :file => 'LICENSE.md'
  }
  s.author = { "Elvis Nunez" => "elvisnunez@me.com" }
  s.social_media_url = "http://twitter.com/NSElvis"
  s.platform = :ios, '6.0'
  s.source = {
    :git => 'https://github.com/NSElvis/NSJSONSerialization-ANDYJSONFile.git',
    :tag => s.version.to_s
  }
  s.source_files = 'NSJSONSerialization-ANDYJSONFile/'
  s.frameworks = 'Foundation'
  s.requires_arc = true
end
