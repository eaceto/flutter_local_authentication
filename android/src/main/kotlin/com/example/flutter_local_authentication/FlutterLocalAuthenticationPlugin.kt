package com.example.flutter_local_authentication

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

/** FlutterLocalAuthenticationPlugin */
class FlutterLocalAuthenticationPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: FlutterFragmentActivity? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_local_authentication")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
          "supportsAuthentication" -> result.success(supportsAuthentication())
          "authenticate" -> authenticate(result)
            else -> result.notImplemented()
        }
    }

    private fun supportsAuthentication(): Boolean {
        activity?.let {
            val biometricManager = BiometricManager.from(it)
            return when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG
                    or BiometricManager.Authenticators.DEVICE_CREDENTIAL
                    or BiometricManager.Authenticators.BIOMETRIC_WEAK)) {
              BiometricManager.BIOMETRIC_SUCCESS -> true
                else -> false
            }
        }
        return false
    }

    private fun authenticate(@NonNull result: Result) {
        activity?.let {
            val executor = ContextCompat.getMainExecutor(it)
            val biometricPrompt = BiometricPrompt(it, executor,
                    object : BiometricPrompt.AuthenticationCallback() {
                      override fun onAuthenticationError(errorCode: Int,
                                                         errString: CharSequence) {
                        super.onAuthenticationError(errorCode, errString)
                        result.error("authentication_error", "$errString", null)
                      }

                      override fun onAuthenticationSucceeded(
                              authResult: BiometricPrompt.AuthenticationResult) {
                        super.onAuthenticationSucceeded(authResult)
                        result.success(true)
                      }

                    })

            val promptInfo = BiometricPrompt.PromptInfo.Builder()
                    .setTitle("Biometric login for my app")
                    .setSubtitle("Log in using your biometric credential")
                    .setNegativeButtonText("Use account password")
                    .build()

            biometricPrompt.authenticate(promptInfo)
        }
        result.error("null_pointer_exception", "Activity is null.", null)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity as? FlutterFragmentActivity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity as? FlutterFragmentActivity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
