#
# Run `pod lib lint tdlib.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'tdlib'
  s.version          = '0.0.1'
  s.summary          = 'A Tdlib plugin project.'
  s.description      = <<-DESC
A Flutter plugin for getting commonly used locations on the filesystem.
Downloaded by pub (not CocoaPods).
                       DESC
  s.homepage         = 'https://pub.dev/packages/tdlib/example'
  s.author           = { 'Duc Hoang' => 'duchoang191@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,m,swift}'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.swift_version = '5.0'
  s.static_framework = true
  s.vendored_frameworks = 'Classes/TdLib.xcframework'
end
