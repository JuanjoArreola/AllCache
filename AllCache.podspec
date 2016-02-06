Pod::Spec.new do |s|

  s.name         = "AllCache"
  s.version      = "0.8"
  s.summary      = "AllCache is a swift 2 generic cache for iOS"

  s.homepage     = "https://github.com/JuanjoArreola/AllCache"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Juanjo Arreola" => "juanjo.arreola@gmail.com" }

  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/JuanjoArreola/AllCache.git", :tag => "version_0.8" }
  s.source_files = "AllCache/*.swift"
  s.resources    = "AllCache/AllCache.xcdatamodeld", "AllCache/allcache_properties.plist"
  s.frameworks = "CoreData"
  s.requires_arc = true

end
