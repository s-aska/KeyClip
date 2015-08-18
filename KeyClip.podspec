Pod::Spec.new do |s|
  s.name             = "KeyClip"
  s.version          = "1.2.2"
  s.summary          = "KeyClip is yet another Keychain library written in Swift."
  s.description      = <<-DESC
                         KeyClip is yet another Keychain library written in Swift.
                         Features
                           - Simple interface
                           - Multi Types ( String / NSDictionary / NSData )
                           - Error Handling
                           - Settings ( kSecAttrAccessGroup / kSecAttrService / kSecAttrAccessible )
                           - Works on both iOS & OS X
                       DESC
  s.homepage         = "https://github.com/s-aska/KeyClip"
  s.license          = 'MIT'
  s.author           = { "aska" => "s.aska.org@gmail.com" }
  s.source           = { :git => "https://github.com/s-aska/KeyClip.git", :tag => "#{s.version}" }
  s.social_media_url = 'https://twitter.com/k_katsumi'

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.requires_arc = true

  s.source_files = 'KeyClip/*.swift'
end