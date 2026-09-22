//
//  PluginMethod.swift
//  flutter_local_authentication
//
//  Created by Ezequiel (Kimi) Aceto on 19/10/23.
//  Contact: ezequiel.aceto@gmail.com
//  WebSite: https://kimi.blog

#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif
import Foundation

enum PluginMethod {
    case canAuthenticate(method: AuthenticationMethod?)
    case authenticate(method: AuthenticationMethod?)
    case getAvailability(method: AuthenticationMethod?)
    case getBiometryType
    case cancelAuthentication
    case setTouchIDAuthenticationAllowableReuseDuration(duration: Double)
    case getTouchIDAuthenticationAllowableReuseDuration
    case setLocalizationModel(model: LocalizationModel?)

    static func from(_ call: FlutterMethodCall) -> PluginMethod? {
        switch call.method {
        case "canAuthenticate":
            return .canAuthenticate(method: AuthenticationMethod.from(call.arguments as? [String: Any]))
        case "authenticate":
            return .authenticate(method: AuthenticationMethod.from(call.arguments as? [String: Any]))
        case "getAvailability":
            return .getAvailability(method: AuthenticationMethod.from(call.arguments as? [String: Any]))
        case "getBiometryType":
            return .getBiometryType
        case "cancelAuthentication":
            return .cancelAuthentication
        case "setTouchIDAuthenticationAllowableReuseDuration":
            let arguments = call.arguments as? [String: Any]
            let duration: Double = arguments?["duration"] as? Double ?? 0.0
            return .setTouchIDAuthenticationAllowableReuseDuration(duration: duration)
        case "getTouchIDAuthenticationAllowableReuseDuration":
            return .getTouchIDAuthenticationAllowableReuseDuration
        case "setLocalizationModel":
            let model = LocalizationModel.from(call.arguments as? [String: Any])
            return .setLocalizationModel(model: model)
        default:
            return nil
        }
    }
}
