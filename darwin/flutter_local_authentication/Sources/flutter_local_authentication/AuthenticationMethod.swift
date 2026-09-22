//
//  AuthenticationMethod.swift
//  flutter_local_authentication
//
//  Contact: ezequiel.aceto@gmail.com
//  WebSite: https://kimi.blog

import Foundation

/// The authenticators a user is allowed to use to prove their identity.
///
/// Raw values match the names of the Dart `AuthenticationMethod` enum.
enum AuthenticationMethod: String {
    case biometricsOnly
    case biometricsOrDeviceCredential
    case deviceCredentialOnly

    /// Reads the authentication method from the arguments of a method call.
    ///
    /// - Returns: `.biometricsOnly` when no method is given, or `nil` when the given method is unknown.
    static func from(_ arguments: [String: Any]?) -> AuthenticationMethod? {
        guard let name = arguments?["method"] as? String else {
            return .biometricsOnly
        }
        return AuthenticationMethod(rawValue: name)
    }
}
