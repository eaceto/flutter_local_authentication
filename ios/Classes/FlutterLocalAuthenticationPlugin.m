#import "FlutterLocalAuthenticationPlugin.h"
#if __has_include(<flutter_local_authentication/flutter_local_authentication-Swift.h>)
#import <flutter_local_authentication/flutter_local_authentication-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_local_authentication-Swift.h"
#endif

@implementation FlutterLocalAuthenticationPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterLocalAuthenticationPlugin registerWithRegistrar:registrar];
}
@end
