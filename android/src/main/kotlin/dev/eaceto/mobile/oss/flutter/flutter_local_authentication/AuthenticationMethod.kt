package dev.eaceto.mobile.oss.flutter.flutter_local_authentication

import android.os.Build
import androidx.biometric.BiometricManager.Authenticators

/**
 * The authenticators a user is allowed to use to prove their identity.
 *
 * @property key The name of the matching value of the Dart `AuthenticationMethod` enum.
 * @property authenticators The [Authenticators] bit field used by the biometric APIs.
 */
enum class AuthenticationMethod(val key: String, val authenticators: Int) {
    BIOMETRICS_ONLY(
        "biometricsOnly",
        Authenticators.BIOMETRIC_STRONG or Authenticators.BIOMETRIC_WEAK
    ),
    BIOMETRICS_OR_DEVICE_CREDENTIAL(
        "biometricsOrDeviceCredential",
        Authenticators.BIOMETRIC_STRONG or Authenticators.BIOMETRIC_WEAK or Authenticators.DEVICE_CREDENTIAL
    ),
    DEVICE_CREDENTIAL_ONLY(
        "deviceCredentialOnly",
        Authenticators.DEVICE_CREDENTIAL
    );

    /**
     * Whether the device credential is one of the allowed authenticators.
     */
    val allowsDeviceCredential: Boolean
        get() = authenticators and Authenticators.DEVICE_CREDENTIAL != 0

    /**
     * Whether this method is supported by the Android version of the device.
     *
     * The device credential alone is only supported on Android 11 (API 30) or newer.
     */
    val isSupported: Boolean
        get() = this != DEVICE_CREDENTIAL_ONLY || Build.VERSION.SDK_INT >= Build.VERSION_CODES.R

    companion object {
        /**
         * Reads the authentication method from the arguments of a method call.
         *
         * @param arguments The arguments received from Flutter.
         * @return [BIOMETRICS_ONLY] when no method is given, or null when the given method is unknown.
         */
        fun from(arguments: Map<String, Any>?): AuthenticationMethod? {
            val name = arguments?.get("method") as? String ?: return BIOMETRICS_ONLY
            return entries.firstOrNull { it.key == name }
        }
    }
}
