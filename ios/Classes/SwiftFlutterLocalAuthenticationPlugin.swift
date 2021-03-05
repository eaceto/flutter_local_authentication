import Flutter
import UIKit
import LocalAuthentication

public class SwiftFlutterLocalAuthenticationPlugin: NSObject, FlutterPlugin {

  let context = LAContext()
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_local_authentication", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterLocalAuthenticationPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getSupportsAuthentication":
        context.touchIDAuthenticationAllowableReuseDuration = 0
        
        let (supports, error) = supportsLocalAuthentication(with: .deviceOwnerAuthenticationWithBiometrics)
            
        result(supports && error == nil)
    default:
        result(FlutterMethodNotImplemented)
    }
  }

  fileprivate func supportsLocalAuthentication(with policy: LAPolicy) -> (Bool, Error?) {
    var error: NSError?
    let supportsAuth = context.canEvaluatePolicy(policy, error: &error)
    return (supportsAuth, error)
  }

  fileprivate func authenticate(with policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics, callback: @escaping (Bool, Error?) -> Void) {
    let reason = "validate your user's session."
    context.evaluatePolicy(policy, localizedReason: reason, reply: callback)
  }
}
