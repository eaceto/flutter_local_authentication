//
//  FlutterLocalAuthenticationPlugin.swift
//  flutter_local_authentication
//
//  Created by Ezequiel (Kimi) Aceto on 19/10/23.
//  Contact: ezequiel.aceto@gmail.com
//  WebSite: https://eaceto.dev

import Cocoa
import FlutterMacOS
import LocalAuthentication

/// A Flutter plugin for local biometric authentication on macOS.
///
/// This plugin provides methods to check for biometric authentication support,
/// perform biometric authentication, and manage Touch ID authentication settings.
public class FlutterLocalAuthenticationPlugin: NSObject, FlutterPlugin {

    let context = LAContext()
    var localizationModel = LocalizationModel.default

    /// Registers the plugin with the Flutter engine.
    ///
    /// - Parameters:
    ///   - registrar: The Flutter plugin registrar.
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_local_authentication", binaryMessenger: registrar.messenger)
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
        case .canAuthenticate:
            let (supports, error) = supportsLocalAuthentication(with: .deviceOwnerAuthenticationWithBiometrics)
            result(supports && error == nil)
        case .authenticate:
            authenticate { autheticated, error in
                if let error = error {
                    let flutterError = FlutterError(code: "authentication_error", message: error.localizedDescription, details: nil)
                    result(flutterError)
                    return
                }
                result(autheticated)
            }
        case .setTouchIDAuthenticationAllowableReuseDuration(let duration):
            setTouchIDAuthenticationAllowableReuseDuration(duration)
            return result(context.touchIDAuthenticationAllowableReuseDuration)
        case .getTouchIDAuthenticationAllowableReuseDuration:
            return result(context.touchIDAuthenticationAllowableReuseDuration)
        case .setLocalizationModel(let model):
            if let model {
                localizationModel = model
            }
        }
    }

    /// Checks if biometric authentication is supported on the device.
    ///
    /// - Parameters:
    ///   - policy: The authentication policy to check.
    /// - Returns: A tuple containing a boolean indicating support and an optional error.
    fileprivate func supportsLocalAuthentication(with policy: LAPolicy) -> (Bool, Error?) {
        var error: NSError?
        let supportsAuth = context.canEvaluatePolicy(policy, error: &error)
        return (supportsAuth, error)
    }

    /// Performs biometric authentication with a given policy.
    ///
    /// - Parameters:
    ///   - policy: The authentication policy to use.
    ///   - callback: A callback to handle the authentication result.
    fileprivate func authenticate(with policy: LAPolicy = .deviceOwnerAuthentication, callback: @escaping (Bool, Error?) -> Void) {
        context.evaluatePolicy(policy, localizedReason: localizationModel.reason, reply: callback)
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
        context.touchIDAuthenticationAllowableReuseDuration = duration
    }

    /// Retrieves the allowable reuse duration for Touch ID authentication.
    ///
    /// - Returns: The allowable reuse duration in seconds.
    fileprivate func getTouchIDAuthenticationAllowableReuseDuration() -> Double {
        return context.touchIDAuthenticationAllowableReuseDuration
    }
}
