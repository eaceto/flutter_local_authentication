package dev.eaceto.mobile.oss.flutter.flutter_local_authentication

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt

/**
 * The reason why the user was not authenticated.
 *
 * @property key The name of the matching value of the Dart `AuthenticationErrorReason` enum.
 */
enum class AuthenticationErrorReason(val key: String) {
    USER_CANCELED("userCanceled"),
    SYSTEM_CANCELED("systemCanceled"),
    LOCKED_OUT("lockedOut"),
    NOT_ENROLLED("notEnrolled"),
    NOT_AVAILABLE("notAvailable"),
    CREDENTIAL_NOT_SET("credentialNotSet"),
    FAILED("failed");

    companion object {
        /**
         * Returns the reason that matches an error code reported by [BiometricPrompt].
         *
         * @param errorCode The error code received in `onAuthenticationError`.
         */
        fun from(errorCode: Int): AuthenticationErrorReason {
            return when (errorCode) {
                BiometricPrompt.ERROR_USER_CANCELED,
                BiometricPrompt.ERROR_NEGATIVE_BUTTON -> USER_CANCELED
                BiometricPrompt.ERROR_CANCELED -> SYSTEM_CANCELED
                BiometricPrompt.ERROR_LOCKOUT,
                BiometricPrompt.ERROR_LOCKOUT_PERMANENT -> LOCKED_OUT
                BiometricPrompt.ERROR_NO_BIOMETRICS -> NOT_ENROLLED
                BiometricPrompt.ERROR_HW_UNAVAILABLE,
                BiometricPrompt.ERROR_HW_NOT_PRESENT,
                BiometricPrompt.ERROR_SECURITY_UPDATE_REQUIRED -> NOT_AVAILABLE
                BiometricPrompt.ERROR_NO_DEVICE_CREDENTIAL -> CREDENTIAL_NOT_SET
                else -> FAILED
            }
        }
    }
}

/**
 * Whether the user can authenticate with a method, and the reason why when they can not.
 *
 * @property key The name of the matching value of the Dart `AuthenticationAvailability` enum.
 */
enum class AuthenticationAvailability(val key: String) {
    AVAILABLE("available"),
    NOT_AVAILABLE("notAvailable"),
    NOT_ENROLLED("notEnrolled"),
    CREDENTIAL_NOT_SET("credentialNotSet"),
    UNSUPPORTED_METHOD("unsupportedMethod");

    companion object {
        /**
         * Returns the availability of an authentication method on the device.
         *
         * @param context The context used to query the [BiometricManager].
         * @param method The authentication method to check.
         */
        fun of(context: Context, method: AuthenticationMethod): AuthenticationAvailability {
            if (!method.isSupported) {
                return UNSUPPORTED_METHOD
            }
            return when (BiometricManager.from(context).canAuthenticate(method.authenticators)) {
                BiometricManager.BIOMETRIC_SUCCESS -> AVAILABLE
                // Nothing is enrolled. When the device credential is allowed, setting it is enough.
                BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED ->
                    if (method.allowsDeviceCredential) CREDENTIAL_NOT_SET else NOT_ENROLLED
                else -> NOT_AVAILABLE
            }
        }
    }
}

/**
 * The kind of biometrics of the device.
 *
 * @property key The name of the matching value of the Dart `BiometryType` enum.
 */
enum class BiometryType(val key: String) {
    NONE("none"),
    FINGERPRINT("fingerprint"),
    FACE("face"),
    IRIS("iris"),
    MULTIPLE("multiple");

    companion object {
        /**
         * Returns the kind of biometric hardware of the device.
         *
         * Android does not tell which biometrics the user enrolled or is going to use, so
         * [MULTIPLE] is returned when the device has more than one kind of hardware.
         *
         * @param context The context used to query the features of the device.
         */
        fun of(context: Context): BiometryType {
            val packageManager = context.packageManager
            val types = mutableListOf<BiometryType>()
            if (packageManager.hasSystemFeature(PackageManager.FEATURE_FINGERPRINT)) {
                types.add(FINGERPRINT)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                if (packageManager.hasSystemFeature(PackageManager.FEATURE_FACE)) {
                    types.add(FACE)
                }
                if (packageManager.hasSystemFeature(PackageManager.FEATURE_IRIS)) {
                    types.add(IRIS)
                }
            }
            return when (types.size) {
                0 -> NONE
                1 -> types.first()
                else -> MULTIPLE
            }
        }
    }
}
