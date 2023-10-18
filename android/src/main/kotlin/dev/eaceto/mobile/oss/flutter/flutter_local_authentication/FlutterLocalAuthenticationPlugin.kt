package dev.eaceto.mobile.oss.flutter.flutter_local_authentication

import androidx.annotation.NonNull
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * A Flutter plugin for local biometric authentication.
 *
 * This plugin provides methods to check if biometric authentication is supported on the device
 * and to trigger biometric authentication prompts.
 *
 * Author: Ezequiel (Kimi) Aceto
 * Email: ezequiel.aceto@gmail.com
 * Website: https://eaceto.dev
 */
class FlutterLocalAuthenticationPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: FlutterFragmentActivity? = null

    companion object {
        private const val CHANNEL = "flutter_local_authentication"
        private val allowedAuthenticators = BiometricManager.Authenticators.BIOMETRIC_STRONG
            .or(BiometricManager.Authenticators.BIOMETRIC_WEAK)
            .or(BiometricManager.Authenticators.DEVICE_CREDENTIAL)
    }

    /**
     * Called when the plugin is attached to the Flutter engine.
     *
     * Initializes the MethodChannel and sets the method call handler.
     *
     * @param flutterPluginBinding The FlutterPluginBinding instance.
     */
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
    }

    /**
     * Called when the plugin is detached from the Flutter engine.
     *
     * Removes the method call handler.
     *
     * @param binding The FlutterPluginBinding instance.
     */
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    /**
     * Handles method calls from Flutter.
     *
     * @param call The method call.
     * @param result The result to send back to Flutter.
     */
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "canAuthenticate" -> result.success(canAuthenticate())
            "authenticate" -> authenticate(result)
            else -> result.notImplemented()
        }
    }

    /**
     * Checks if biometric authentication is supported on the device.
     *
     * @return `true` if biometric authentication is supported, `false` otherwise.
     */
    private fun canAuthenticate(): Boolean {
        val biometricManager = BiometricManager.from(activity!!)
        return when (biometricManager.canAuthenticate(allowedAuthenticators)) {
            BiometricManager.BIOMETRIC_SUCCESS -> true
            else -> false
        }
    }

    /**
     * Initiates biometric authentication and returns the result to Flutter.
     *
     * @param result The result to send back to Flutter.
     */
    private fun authenticate(@NonNull result: Result) {
        activity?.let {
            val executor = ContextCompat.getMainExecutor(it)
            val biometricPrompt = BiometricPrompt(it, executor,
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationError(errorCode: Int, errorMessage: CharSequence) {
                        val details = mapOf(
                            "errorCode" to errorCode,
                            "message" to errorMessage.toString()
                        )
                        result.error("authentication_error", errorMessage.toString(), details)
                    }

                    override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult) {
                        result.success(true)
                    }
                })

            val promptInfo = BiometricPrompt.PromptInfo.Builder()
                .setTitle("Local Authentication Required")
                .setSubtitle("Validate access to this device.")
                .setNegativeButtonText("Cancel")
                .build()

            biometricPrompt.authenticate(promptInfo)
        } ?: run {
            result.error(
                "null_pointer_exception",
                "FragmentActivity is null. ",
                "Beware that a FlutterFragmentActivity is required instead of a FlutterActivity."
            )
        }
    }

    /**
     * Called when the plugin is attached to an Android activity.
     *
     * Sets the activity and method call handler.
     *
     * @param binding The ActivityPluginBinding instance.
     */
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity as FlutterFragmentActivity
        channel.setMethodCallHandler(this)
    }

    /**
     * Called when the plugin is detached from an Android activity during configuration changes.
     */
    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    /**
     * Called when the plugin is reattached to an Android activity after configuration changes.
     *
     * Sets the activity and method call handler.
     *
     * @param binding The ActivityPluginBinding instance.
     */
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity as FlutterFragmentActivity
        channel.setMethodCallHandler(this)
    }

    /**
     * Called when the plugin is detached from an Android activity.
     */
    override fun onDetachedFromActivity() {
        activity = null
    }
}
