package com.example.flutter_local_authentication

import android.content.Context
import android.hardware.fingerprint.FingerprintManager
import androidx.annotation.NonNull
import androidx.biometric.BiometricManager
import androidx.core.hardware.fingerprint.FingerprintManagerCompat
import io.flutter.embedding.android.FlutterActivity

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FlutterLocalAuthenticationPlugin */
class FlutterLocalAuthenticationPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private var activity: FlutterActivity? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_local_authentication")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getSupportsAuthentication") {

      if (activity != null) {
        val supportsBiometrics = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
          val biometricManager = BiometricManager.from(activity!!)
          when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG
                  or BiometricManager.Authenticators.DEVICE_CREDENTIAL
                  or BiometricManager.Authenticators.BIOMETRIC_WEAK)) {
            BiometricManager.BIOMETRIC_SUCCESS -> true
            else -> false
          }
        } else {
          val fingerprintManager: FingerprintManager = activity!!.context.getSystemService(Context.FINGERPRINT_SERVICE) as FingerprintManager
          fingerprintManager.isHardwareDetected && fingerprintManager.hasEnrolledFingerprints()
        }
        result.success(supportsBiometrics)
        return
      }
      result.success(false)
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity as? FlutterActivity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity as? FlutterActivity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}
