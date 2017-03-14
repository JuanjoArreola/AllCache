Pod::Spec.new do |s|

  s.name         = "AllCache"
  s.version      = "2.2.0"
  s.summary      = "AllCache is a swift 3 generic cache for iOS"

  s.homepage     = "https://github.com/JuanjoArreola/AllCache"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Juanjo Arreola" => "juanjo.arreola@gmail.com" }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"

  s.source       = { :git => "https://github.com/JuanjoArreola/AllCache.git", :tag => "#{s.version}" }
  s.source_files = "Sources/*.swift"
  s.requires_arc = true

end
