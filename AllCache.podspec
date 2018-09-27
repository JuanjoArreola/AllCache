Pod::Spec.new do |s|

  s.name         = "AllCache"
  s.version      = "3.4.0"
  s.summary      = "AllCache is a swift 4 generic cache"

  s.homepage     = "https://github.com/JuanjoArreola/AllCache"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Juanjo Arreola" => "juanjo.arreola@gmail.com" }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.tvos.deployment_target = "9.0"
  s.watchos.deployment_target = "2.0"

  s.source       = { :git => "https://github.com/JuanjoArreola/AllCache.git", :tag => "#{s.version}" }
  s.source_files = "Sources/*.swift"
  s.requires_arc = true

  s.dependency "Logg", "~> 2.0.0"
  s.dependency "AsyncRequest", "~> 2.1.0"

  s.swift_version = '4.2'

end
