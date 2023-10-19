package dev.eaceto.mobile.oss.flutter.flutter_local_authentication

import io.flutter.plugin.common.MethodCall

/**
 * Represents methods available in the Flutter Local Authentication plugin.
 */
sealed class PluginMethod {
    /**
     * Check if biometric authentication is available on the device.
     */
    object CanAuthenticate : PluginMethod()

    /**
     * Perform biometric authentication.
     */
    object Authenticate : PluginMethod()

    /**
     * Set the allowable reuse duration for Touch ID authentication (iOS/macOS only).
     *
     * @property duration The allowable reuse duration in seconds.
     */
    data class SetTouchIDAuthenticationAllowableReuseDuration(val duration: Double) : PluginMethod()

    /**
     * Get the allowable reuse duration for Touch ID authentication (iOS/macOS only).
     */
    object GetTouchIDAuthenticationAllowableReuseDuration : PluginMethod()

    /**
     * Set the localization model for the plugin.
     *
     * @property model The localization model to set.
     */
    data class SetLocalizationModel(val model: LocalizationModel?) : PluginMethod()

    companion object {
        /**
         * Creates a [PluginMethod] instance based on the provided [MethodCall].
         *
         * @param call The [MethodCall] received from Flutter.
         * @return The corresponding [PluginMethod] or null if not recognized.
         */
        fun from(call: MethodCall): PluginMethod? {
            return when (call.method) {
                "canAuthenticate" -> CanAuthenticate
                "authenticate" -> Authenticate
                "setTouchIDAuthenticationAllowableReuseDuration" -> {
                    val arguments = call.arguments as? Map<String, Any>
                    val duration = arguments?.get("duration") as? Double ?: 0.0
                    SetTouchIDAuthenticationAllowableReuseDuration(duration)
                }
                "getTouchIDAuthenticationAllowableReuseDuration" -> GetTouchIDAuthenticationAllowableReuseDuration
                "setLocalizationModel" -> {
                    val model = LocalizationModel.from(call.arguments as? Map<String, Any>)
                    SetLocalizationModel(model)
                }
                else -> null
            }
        }
    }
}
