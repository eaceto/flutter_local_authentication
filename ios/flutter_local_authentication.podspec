#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_local_authentication.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_local_authentication'
  s.version          = '1.1.0'
  s.summary          = 'A flutter plugin that allows access to Local Authentication'
  s.description      = <<-DESC
A flutter plugin that allows access to Local Authentication / Biometrics on iOS, macOS, Linux and Android.
                       DESC
  s.homepage         = 'https://eaceto.dev'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Ezequiel (Kimi) Aceto' => 'ezequiel.aceto@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.framework = 'LocalAuthentication'

  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
