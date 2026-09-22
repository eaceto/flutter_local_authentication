package dev.eaceto.mobile.oss.flutter.flutter_local_authentication

import android.content.Context
import androidx.annotation.NonNull
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
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
 * Website: https://kimi.blog
 */
class FlutterLocalAuthenticationPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    /** The host activity, when it is a [FragmentActivity] as required by [BiometricPrompt]. */
    private var activity: FragmentActivity? = null
    private var applicationContext: Context? = null
    private var currentPrompt: BiometricPrompt? = null
    private var localizationModel = LocalizationModel.default

    companion object {
        private const val CHANNEL = "flutter_local_authentication"
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
        applicationContext = flutterPluginBinding.applicationContext
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
        applicationContext = null
    }

    /**
     * Handles method calls from Flutter.
     *
     * @param call The method call.
     * @param result The result to send back to Flutter.
     */
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        val method = PluginMethod.from(call)
        when (method) {
            is PluginMethod.CanAuthenticate -> method.method?.let {
                result.success(canAuthenticate(it))
            } ?: unknownAuthenticationMethod(result)
            is PluginMethod.GetAvailability -> method.method?.let {
                result.success(availability(it).key)
            } ?: unknownAuthenticationMethod(result)
            is PluginMethod.GetBiometryType -> result.success(biometryType().key)
            is PluginMethod.Authenticate -> method.method?.let {
                authenticate(it, result)
            } ?: unknownAuthenticationMethod(result)
            is PluginMethod.CancelAuthentication -> result.success(cancelAuthentication())
            is PluginMethod.SetLocalizationModel -> {
                setLocalizationModel(method.model)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun unknownAuthenticationMethod(@NonNull result: Result) {
        result.error("invalid_arguments", "Unknown authentication method.", null)
    }

    /**
     * Checks if the user can authenticate with the given method on the device.
     *
     * @param method The authentication method to check.
     * @return `true` if the method is supported and available, `false` otherwise.
     */
    private fun canAuthenticate(method: AuthenticationMethod): Boolean {
        return availability(method) == AuthenticationAvailability.AVAILABLE
    }

    /**
     * Checks the availability of the given method on the device.
     *
     * @param method The authentication method to check.
     * @return The availability of the method, with the reason why when it is not available.
     */
    private fun availability(method: AuthenticationMethod): AuthenticationAvailability {
        val context = activity ?: applicationContext ?: return AuthenticationAvailability.NOT_AVAILABLE
        return AuthenticationAvailability.of(context, method)
    }

    /**
     * Returns the kind of biometric hardware of the device.
     */
    private fun biometryType(): BiometryType {
        val context = activity ?: applicationContext ?: return BiometryType.NONE
        return BiometryType.of(context)
    }

    /**
     * Dismisses the authentication prompt that is being shown.
     *
     * The authentication in progress fails with [BiometricPrompt.ERROR_CANCELED].
     *
     * @return `true` if there was a prompt to dismiss, `false` otherwise.
     */
    private fun cancelAuthentication(): Boolean {
        val prompt = currentPrompt ?: return false
        prompt.cancelAuthentication()
        return true
    }

    /**
     * Initiates authentication with the given method and returns the result to Flutter.
     *
     * @param method The authentication method to use.
     * @param result The result to send back to Flutter.
     */
    private fun authenticate(method: AuthenticationMethod, @NonNull result: Result) {
        if (!method.isSupported) {
            result.error(
                "unsupported_method",
                "Authentication method '${method.key}' is not supported on this version of Android.",
                null
            )
            return
        }
        activity?.let {
            val executor = ContextCompat.getMainExecutor(it)
            val biometricPrompt = BiometricPrompt(it, executor,
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationError(errorCode: Int, errorMessage: CharSequence) {
                        currentPrompt = null
                        val details = mapOf(
                            "reason" to AuthenticationErrorReason.from(errorCode).key,
                            "errorCode" to errorCode,
                            "message" to errorMessage.toString()
                        )
                        result.error("authentication_error", errorMessage.toString(), details)
                    }

                    override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult) {
                        currentPrompt = null
                        result.success(true)
                    }
                })
            currentPrompt = biometricPrompt

            val promptInfoBuilder = BiometricPrompt.PromptInfo.Builder()
                .setTitle(localizationModel.dialogTitle)
                .setSubtitle(localizationModel.reason)
                .setAllowedAuthenticators(method.authenticators)
            // A negative button is not allowed when the device credential is an allowed authenticator.
            if (!method.allowsDeviceCredential) {
                promptInfoBuilder.setNegativeButtonText(localizationModel.cancelButtonTitle)
            }

            biometricPrompt.authenticate(promptInfoBuilder.build())
        } ?: run {
            result.error(
                "null_pointer_exception",
                "The plugin is not attached to a FragmentActivity.",
                "BiometricPrompt needs a FragmentActivity: make your MainActivity extend FlutterFragmentActivity instead of FlutterActivity."
            )
        }
    }

    private fun setLocalizationModel(model: LocalizationModel?) {
        model?.let {
            localizationModel = it
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
        // Only a FragmentActivity can show a BiometricPrompt. Any other host still gets
        // canAuthenticate / getAvailability, and a descriptive error from authenticate.
        activity = binding.activity as? FragmentActivity
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
        // Only a FragmentActivity can show a BiometricPrompt. Any other host still gets
        // canAuthenticate / getAvailability, and a descriptive error from authenticate.
        activity = binding.activity as? FragmentActivity
        channel.setMethodCallHandler(this)
    }

    /**
     * Called when the plugin is detached from an Android activity.
     */
    override fun onDetachedFromActivity() {
        activity = null
    }
}
