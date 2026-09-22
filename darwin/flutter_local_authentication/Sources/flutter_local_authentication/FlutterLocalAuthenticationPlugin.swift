//
//  FlutterLocalAuthenticationPlugin.swift
//  flutter_local_authentication
//
//  Created by Ezequiel (Kimi) Aceto on 19/10/23.
//  Contact: ezequiel.aceto@gmail.com
//  WebSite: https://kimi.blog

#if os(iOS)
@preconcurrency import Flutter
#elseif os(macOS)
@preconcurrency import FlutterMacOS
#endif
import Foundation
import LocalAuthentication
import Security

/// A Flutter plugin for local biometric authentication on iOS and macOS.
///
/// This plugin provides methods to check for biometric authentication support,
/// perform biometric authentication, and manage Touch ID authentication settings.
public class FlutterLocalAuthenticationPlugin: NSObject, FlutterPlugin {

    var touchIDAuthenticationAllowableReuseDuration: TimeInterval = 0
    var localizationModel = LocalizationModel.default
    /// The context of the authentication that is in progress, if any.
    fileprivate var currentContext: LAContext?

    /// Registers the plugin with the Flutter engine.
    ///
    /// - Parameters:
    ///   - registrar: The Flutter plugin registrar.
    public static func register(with registrar: FlutterPluginRegistrar) {
        // The registrar's `messenger` is a method on iOS and a property on macOS.
        #if os(iOS)
        let messenger = registrar.messenger()
        #else
        let messenger = registrar.messenger
        #endif
        let channel = FlutterMethodChannel(name: "flutter_local_authentication", binaryMessenger: messenger)
        let instance = FlutterLocalAuthenticationPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    /// Handles method calls from Flutter.
    ///
    /// - Parameters:
    ///   - call: The method call received from Flutter.
    ///   - result: The result callback to send the response back to Flutter.
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let method = PluginMethod.from(call) else {
            return result(FlutterMethodNotImplemented)
        }
        switch method {
        case .canAuthenticate(let method):
            guard let method else {
                return result(FlutterLocalAuthenticationPlugin.unknownMethodError)
            }
            result(availability(of: method) == .available)
        case .getAvailability(let method):
            guard let method else {
                return result(FlutterLocalAuthenticationPlugin.unknownMethodError)
            }
            result(availability(of: method).rawValue)
        case .getBiometryType:
            result(biometryType().rawValue)
        case .authenticate(let method):
            guard let method else {
                return result(FlutterLocalAuthenticationPlugin.unknownMethodError)
            }
            let context = makeContext()
            currentContext = context
            let reply = AuthenticationReply(result: result) { [weak self] in
                if self?.currentContext === context {
                    self?.currentContext = nil
                }
            }
            authenticate(with: method, context: context) { authenticated, error in
                reply(authenticated: authenticated, error: error)
            }
        case .cancelAuthentication:
            guard let context = currentContext else {
                return result(false)
            }
            // The authentication in progress fails with `LAError.appCancel`.
            context.invalidate()
            result(true)
        case .setTouchIDAuthenticationAllowableReuseDuration(let duration):
            setTouchIDAuthenticationAllowableReuseDuration(duration)
            return result(touchIDAuthenticationAllowableReuseDuration)
        case .getTouchIDAuthenticationAllowableReuseDuration:
            return result(touchIDAuthenticationAllowableReuseDuration)
        case .setLocalizationModel(let model):
            if let model {
                localizationModel = model
            }
            result(nil)
        }
    }

    fileprivate static var unknownMethodError: FlutterError {
        return FlutterError(code: "invalid_arguments", message: "Unknown authentication method.", details: nil)
    }

    /// Creates a new context for an evaluation.
    ///
    /// A context stays authenticated after a successful evaluation, so each evaluation
    /// uses its own context. Otherwise a previous success (e.g. with biometrics) would
    /// satisfy a later request for a different authentication method without prompting.
    fileprivate func makeContext() -> LAContext {
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = touchIDAuthenticationAllowableReuseDuration
        return context
    }

    /// The policy used to check if the user can authenticate with a given method.
    ///
    /// - Parameters:
    ///   - method: The authentication method to check.
    /// - Returns: The policy that must be evaluable for the method to be available.
    fileprivate func canEvaluatePolicy(for method: AuthenticationMethod) -> LAPolicy {
        switch method {
        case .biometricsOnly:
            return .deviceOwnerAuthenticationWithBiometrics
        case .biometricsOrDeviceCredential, .deviceCredentialOnly:
            // Can be evaluated as long as the device has a passcode / password set.
            return .deviceOwnerAuthentication
        }
    }

    /// Checks if the user can authenticate with a given method.
    ///
    /// - Parameters:
    ///   - method: The authentication method to check.
    /// - Returns: The availability of the method, with the reason why when it is not available.
    fileprivate func availability(of method: AuthenticationMethod) -> AuthenticationAvailability {
        var error: NSError?
        let canEvaluatePolicy = makeContext().canEvaluatePolicy(canEvaluatePolicy(for: method), error: &error)
        return AuthenticationAvailability(canEvaluatePolicy: canEvaluatePolicy, error: error)
    }

    /// The kind of biometrics of the device.
    fileprivate func biometryType() -> BiometryType {
        let context = LAContext()
        // The biometry type is only set after checking if a policy can be evaluated.
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return BiometryType(context.biometryType)
    }

    /// Performs authentication with a given method.
    ///
    /// - Parameters:
    ///   - method: The authentication method to use.
    ///   - context: The context that performs the authentication.
    ///   - callback: A callback to handle the authentication result.
    fileprivate func authenticate(with method: AuthenticationMethod, context: LAContext, callback: @escaping @Sendable (Bool, Error?) -> Void) {
        context.localizedCancelTitle = localizationModel.cancelButtonTitle
        switch method {
        case .biometricsOnly:
            // Hides the fallback button, as the device credential is not an allowed authenticator.
            context.localizedFallbackTitle = ""
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: localizationModel.reason, reply: callback)
        case .biometricsOrDeviceCredential:
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: localizationModel.reason, reply: callback)
        case .deviceCredentialOnly:
            // There is no LAPolicy for the device credential alone, so an access control
            // that only accepts the device passcode / password is evaluated instead.
            var accessControlError: Unmanaged<CFError>?
            guard let accessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                                      kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                                      .devicePasscode,
                                                                      &accessControlError) else {
                return callback(false, accessControlError?.takeRetainedValue())
            }
            context.evaluateAccessControl(accessControl, operation: .useItem, localizedReason: localizationModel.reason, reply: callback)
        }
    }

    /// Sets the allowable reuse duration for Touch ID authentication.
    ///
    /// - Parameters:
    ///   - duration: The allowable reuse duration in seconds.
    fileprivate func setTouchIDAuthenticationAllowableReuseDuration(_ duration: Double) {
        var duration = duration
        if duration > LATouchIDAuthenticationMaximumAllowableReuseDuration {
            duration = LATouchIDAuthenticationMaximumAllowableReuseDuration
        }
        touchIDAuthenticationAllowableReuseDuration = duration
    }

    /// Retrieves the allowable reuse duration for Touch ID authentication.
    ///
    /// - Returns: The allowable reuse duration in seconds.
    fileprivate func getTouchIDAuthenticationAllowableReuseDuration() -> Double {
        return touchIDAuthenticationAllowableReuseDuration
    }
}

/// Delivers the result of an authentication to Flutter on the main queue.
///
/// `FlutterResult` and the completion are not `Sendable`, but handing them over to the main
/// queue is safe as long as they are only called from there, which this type guarantees.
fileprivate struct AuthenticationReply: @unchecked Sendable {
    let result: FlutterResult
    let onComplete: () -> Void

    func callAsFunction(authenticated: Bool, error: Error?) {
        DispatchQueue.main.async {
            onComplete()
            guard let error else {
                return result(authenticated)
            }
            let details: [String: Any] = [
                "reason": AuthenticationErrorReason(error: error).rawValue,
                "errorCode": (error as NSError).code,
                "message": error.localizedDescription
            ]
            result(FlutterError(code: "authentication_error", message: error.localizedDescription, details: details))
        }
    }
}
