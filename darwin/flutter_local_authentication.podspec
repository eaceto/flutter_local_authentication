#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_local_authentication.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_local_authentication'
  s.version          = '2.1.1'
  s.summary          = 'A flutter plugin that allows access to Local Authentication'
  s.description      = <<-DESC
A flutter plugin that allows access to Local Authentication / Biometrics on iOS, macOS, Linux and Android.
                       DESC
  s.homepage         = 'https://kimi.blog'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Ezequiel (Kimi) Aceto' => 'ezequiel.aceto@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_local_authentication/Sources/flutter_local_authentication/**/*.swift'
  s.framework = 'LocalAuthentication'

  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'

  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.ios.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.osx.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '6.0'
end
