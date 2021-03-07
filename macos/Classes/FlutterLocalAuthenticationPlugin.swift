import Cocoa
import LocalAuthentication
import FlutterMacOS

public class FlutterLocalAuthenticationPlugin: NSObject, FlutterPlugin {
    
    let context = LAContext()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_local_authentication", binaryMessenger: registrar.messenger)
        let instance = FlutterLocalAuthenticationPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        context.touchIDAuthenticationAllowableReuseDuration = 0
        switch call.method {
        case "supportsAuthentication":
            let (supports, error) = supportsLocalAuthentication(with: .deviceOwnerAuthentication)
            result(supports && error == nil)
        case "authenticate":
            authenticate() { autheticated, error in
                if let error = error {
                    let flutterError = FlutterError(code: "authentication_error", message: error.localizedDescription, details: nil)
                    result(flutterError)
                    return
                }
                result(autheticated)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    fileprivate func supportsLocalAuthentication(with policy: LAPolicy) -> (Bool, Error?) {
        var error: NSError?
        let supportsAuth = context.canEvaluatePolicy(policy, error: &error)
        return (supportsAuth, error)
    }

    fileprivate func authenticate(with policy: LAPolicy = .deviceOwnerAuthentication, callback: @escaping (Bool, Error?) -> Void) {
        let reason = "validate your user's session."
        context.evaluatePolicy(policy, localizedReason: reason, reply: callback)
    }
}
