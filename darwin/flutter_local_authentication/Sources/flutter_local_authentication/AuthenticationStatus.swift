//
//  AuthenticationStatus.swift
//  flutter_local_authentication
//
//  Contact: ezequiel.aceto@gmail.com
//  WebSite: https://kimi.blog

import Foundation
import LocalAuthentication

/// The reason why the user was not authenticated.
///
/// Raw values match the names of the Dart `AuthenticationErrorReason` enum.
enum AuthenticationErrorReason: String {
    case userCanceled
    case systemCanceled
    case lockedOut
    case notEnrolled
    case notAvailable
    case credentialNotSet
    case failed

    /// Creates the reason that matches an error reported by Local Authentication.
    init(error: Error) {
        let error = error as NSError
        guard error.domain == LAError.errorDomain, let code = LAError.Code(rawValue: error.code) else {
            self = .failed
            return
        }
        #if os(macOS)
        if code == .biometryNotPaired || code == .biometryDisconnected {
            self = .notAvailable
            return
        }
        #endif
        switch code {
        case .userCancel:
            self = .userCanceled
        case .systemCancel, .appCancel:
            self = .systemCanceled
        case .biometryLockout:
            self = .lockedOut
        case .biometryNotEnrolled:
            self = .notEnrolled
        case .biometryNotAvailable:
            self = .notAvailable
        case .passcodeNotSet:
            self = .credentialNotSet
        default:
            self = .failed
        }
    }
}

/// Whether the user can authenticate with a method, and the reason why when they can not.
///
/// Raw values match the names of the Dart `AuthenticationAvailability` enum.
enum AuthenticationAvailability: String {
    case available
    case notAvailable
    case notEnrolled
    case lockedOut
    case credentialNotSet

    /// Creates the availability that matches the result of checking if a policy can be evaluated.
    init(canEvaluatePolicy: Bool, error: Error?) {
        guard let error else {
            self = canEvaluatePolicy ? .available : .notAvailable
            return
        }
        switch AuthenticationErrorReason(error: error) {
        case .lockedOut:
            self = .lockedOut
        case .notEnrolled:
            self = .notEnrolled
        case .credentialNotSet:
            self = .credentialNotSet
        default:
            self = .notAvailable
        }
    }
}

/// The kind of biometrics of the device.
///
/// Raw values match the names of the Dart `BiometryType` enum.
enum BiometryType: String {
    case none
    case fingerprint
    case face
    case iris

    /// Creates the type that matches the biometry type reported by Local Authentication.
    init(_ biometryType: LABiometryType) {
        if #available(iOS 17.0, macOS 14.0, *), biometryType == .opticID {
            self = .iris
            return
        }
        switch biometryType {
        case .touchID:
            self = .fingerprint
        case .faceID:
            self = .face
        default:
            self = .none
        }
    }
}
