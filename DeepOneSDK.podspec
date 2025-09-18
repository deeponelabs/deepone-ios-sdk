Pod::Spec.new do |spec|
  spec.name         = "DeepOneSDK"
  spec.version      = "1.1.3"
  spec.summary      = "DeepOne SDK for iOS - Deep Linking and Attribution"
  spec.description  = <<-DESC
                      DeepOne SDK provides comprehensive deep linking and attribution 
                      capabilities for iOS applications. This framework includes link creation,
                      attribution tracking, and seamless user experience management.
                      DESC

  spec.homepage     = "https://github.com/deeponelabs/deepone-ios-sdk"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "DeepOneIO" => "contact@deeponeio.io" }
  spec.source       = { :git => "https://github.com/deeponelabs/deepone-ios-sdk.git", :tag => "#{spec.version}" }
  
  # Public framework source files
  spec.source_files = "DeepOneSDK/**/*.{h,m,swift}"
  spec.public_header_files = "DeepOneSDK/**/*.h"
  
  # Dependencies
  spec.vendored_frameworks = "Frameworks/DeepOneNetworking.xcframework"
  
  # Build settings
  spec.frameworks = "Foundation", "UIKit", "Security"
  spec.requires_arc = true
  spec.swift_version = "5.5"
  
  # Module settings
  spec.module_name = "DeepOneSDK"
  spec.platform     = :ios, '13.0'
  spec.pod_target_xcconfig = {
    'SUPPORTS_MACCATALYST'    => 'YES',
    'IPHONEOS_DEPLOYMENT_TARGET' => '13.0',
    'MACOSX_DEPLOYMENT_TARGET'   => '10.15'
  }
end
