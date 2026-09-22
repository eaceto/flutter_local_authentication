package dev.eaceto.mobile.oss.flutter.flutter_local_authentication

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import org.mockito.ArgumentMatchers.anyString
import org.mockito.ArgumentMatchers.isNull
import org.mockito.Mockito

/*
 * Unit tests of the Kotlin portion of this plugin's implementation.
 *
 * The plugin is not attached to an engine or an activity, so these tests cover the parsing
 * of method calls and the behaviour without a context. The biometric prompt itself needs a
 * device.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew :flutter_local_authentication:testDebugUnitTest` in the
 * `example/android/` directory, or directly from IDEs that support JUnit such as Android Studio.
 */

internal class FlutterLocalAuthenticationPluginTest {
    private val plugin = FlutterLocalAuthenticationPlugin()

    private fun call(method: String, arguments: Any? = null): MethodChannel.Result {
        val result: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(MethodCall(method, arguments), result)
        return result
    }

    @Test
    fun canAuthenticate_withoutContext_isFalse() {
        Mockito.verify(call("canAuthenticate")).success(false)
    }

    @Test
    fun getAvailability_withoutContext_isNotAvailable() {
        Mockito.verify(call("getAvailability", mapOf("method" to "biometricsOnly"))).success("notAvailable")
    }

    @Test
    fun getBiometryType_withoutContext_isNone() {
        Mockito.verify(call("getBiometryType")).success("none")
    }

    @Test
    fun cancelAuthentication_withoutPrompt_isFalse() {
        Mockito.verify(call("cancelAuthentication")).success(false)
    }

    @Test
    fun unknownAuthenticationMethod_isAnArgumentError() {
        Mockito.verify(call("canAuthenticate", mapOf("method" to "somethingNew")))
            .error(Mockito.eq("invalid_arguments"), anyString(), isNull())
        Mockito.verify(call("authenticate", mapOf("method" to "somethingNew")))
            .error(Mockito.eq("invalid_arguments"), anyString(), isNull())
    }

    @Test
    fun unknownMethodCall_isNotImplemented() {
        Mockito.verify(call("getPlatformVersion")).notImplemented()
    }

    @Test
    fun setLocalizationModel_completes() {
        Mockito.verify(call("setLocalizationModel", mapOf(
            "promptDialogTitle" to "Title",
            "promptDialogReason" to "Reason",
            "cancelButtonTitle" to "Cancel"
        ))).success(null)
    }

    @Test
    fun authenticationMethod_defaultsToBiometricsOnly() {
        assertEquals(AuthenticationMethod.BIOMETRICS_ONLY, AuthenticationMethod.from(null))
        assertEquals(AuthenticationMethod.BIOMETRICS_ONLY, AuthenticationMethod.from(emptyMap()))
        assertEquals(
            AuthenticationMethod.DEVICE_CREDENTIAL_ONLY,
            AuthenticationMethod.from(mapOf("method" to "deviceCredentialOnly"))
        )
        assertNull(AuthenticationMethod.from(mapOf("method" to "somethingNew")))
    }

    @Test
    fun authenticationMethod_allowsDeviceCredential() {
        assertEquals(false, AuthenticationMethod.BIOMETRICS_ONLY.allowsDeviceCredential)
        assertEquals(true, AuthenticationMethod.BIOMETRICS_OR_DEVICE_CREDENTIAL.allowsDeviceCredential)
        assertEquals(true, AuthenticationMethod.DEVICE_CREDENTIAL_ONLY.allowsDeviceCredential)
    }

    @Test
    fun authenticationErrorReason_mapsBiometricPromptErrors() {
        assertEquals(AuthenticationErrorReason.USER_CANCELED, AuthenticationErrorReason.from(10))
        assertEquals(AuthenticationErrorReason.USER_CANCELED, AuthenticationErrorReason.from(13))
        assertEquals(AuthenticationErrorReason.SYSTEM_CANCELED, AuthenticationErrorReason.from(5))
        assertEquals(AuthenticationErrorReason.LOCKED_OUT, AuthenticationErrorReason.from(7))
        assertEquals(AuthenticationErrorReason.LOCKED_OUT, AuthenticationErrorReason.from(9))
        assertEquals(AuthenticationErrorReason.NOT_ENROLLED, AuthenticationErrorReason.from(11))
        assertEquals(AuthenticationErrorReason.NOT_AVAILABLE, AuthenticationErrorReason.from(1))
        assertEquals(AuthenticationErrorReason.NOT_AVAILABLE, AuthenticationErrorReason.from(12))
        assertEquals(AuthenticationErrorReason.CREDENTIAL_NOT_SET, AuthenticationErrorReason.from(14))
        assertEquals(AuthenticationErrorReason.FAILED, AuthenticationErrorReason.from(3))
        assertEquals(AuthenticationErrorReason.FAILED, AuthenticationErrorReason.from(-1))
    }
}
