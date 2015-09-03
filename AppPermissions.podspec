Pod::Spec.new do |spec|
  spec.name         = 'AppPermissions'
  spec.version      = '1.1'
  spec.summary      = 'Swift library for application permissions.'
  spec.homepage     = 'https://github.com/DigitalExpansion/AppPermissions'
  spec.author       = { 'Digital Expansion' => 'de@ad1.ru' }
  spec.source       = { :git => 'https://github.com/DigitalExpansion/AppPermissions.git', :tag => "v#{spec.version}" }
  spec.source_files = 'Source/*.swift'
  spec.requires_arc = true
  spec.license      = { :type => 'MIT', :file => 'LICENSE' }
  spec.frameworks   = 'UIKit'
  spec.ios.deployment_target = "8.0"
end
