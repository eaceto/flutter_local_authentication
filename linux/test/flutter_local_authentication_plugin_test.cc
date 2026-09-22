// Author: Ezequiel (Kimi) Aceto
// Email: ezequiel.aceto@gmail.com
// Website: https://kimi.blog

#include <flutter_linux/flutter_linux.h>
#include <gtest/gtest.h>

#include "flutter_local_authentication_plugin_private.h"

// The tests run without fprintd, so fingerprint authentication is never available.
// They cover the parsing of method calls and the methods that do not need fprintd.

namespace {

FlValue *method_args(const char *method)
{
  FlValue *args = fl_value_new_map();
  fl_value_set_string_take(args, "method", fl_value_new_string(method));
  return args;
}

FlValue *success_value(FlMethodResponse *response)
{
  EXPECT_TRUE(FL_IS_METHOD_SUCCESS_RESPONSE(response));
  return fl_method_success_response_get_result(FL_METHOD_SUCCESS_RESPONSE(response));
}

const gchar *error_code(FlMethodResponse *response)
{
  EXPECT_TRUE(FL_IS_METHOD_ERROR_RESPONSE(response));
  return fl_method_error_response_get_code(FL_METHOD_ERROR_RESPONSE(response));
}

}  // namespace

TEST(FlutterLocalAuthenticationPlugin, CanAuthenticateDefaultsToBiometricsOnly)
{
  g_autoptr(FlMethodResponse) response = flutter_local_authentication_plugin_handle("canAuthenticate", nullptr);
  FlValue *result = success_value(response);
  ASSERT_EQ(fl_value_get_type(result), FL_VALUE_TYPE_BOOL);
  EXPECT_FALSE(fl_value_get_bool(result));
}

TEST(FlutterLocalAuthenticationPlugin, CanAuthenticateIsFalseForUnsupportedMethods)
{
  for (const char *method : {"biometricsOrDeviceCredential", "deviceCredentialOnly"})
  {
    g_autoptr(FlValue) args = method_args(method);
    g_autoptr(FlMethodResponse) response = flutter_local_authentication_plugin_handle("canAuthenticate", args);
    EXPECT_FALSE(fl_value_get_bool(success_value(response)));
  }
}

TEST(FlutterLocalAuthenticationPlugin, GetAvailabilityReportsUnsupportedMethods)
{
  for (const char *method : {"biometricsOrDeviceCredential", "deviceCredentialOnly"})
  {
    g_autoptr(FlValue) args = method_args(method);
    g_autoptr(FlMethodResponse) response = flutter_local_authentication_plugin_handle("getAvailability", args);
    EXPECT_STREQ(fl_value_get_string(success_value(response)), "unsupportedMethod");
  }
}

TEST(FlutterLocalAuthenticationPlugin, GetAvailabilityWithoutFprintdIsNotAvailable)
{
  g_autoptr(FlValue) args = method_args("biometricsOnly");
  g_autoptr(FlMethodResponse) response = flutter_local_authentication_plugin_handle("getAvailability", args);
  EXPECT_STREQ(fl_value_get_string(success_value(response)), "notAvailable");
}

TEST(FlutterLocalAuthenticationPlugin, GetBiometryTypeWithoutFprintdIsNone)
{
  g_autoptr(FlMethodResponse) response = flutter_local_authentication_plugin_handle("getBiometryType", nullptr);
  EXPECT_STREQ(fl_value_get_string(success_value(response)), "none");
}

TEST(FlutterLocalAuthenticationPlugin, AuthenticateWithUnsupportedMethodIsAnError)
{
  g_autoptr(FlValue) args = method_args("deviceCredentialOnly");
  g_autoptr(FlMethodResponse) response = flutter_local_authentication_plugin_handle("authenticate", args);
  EXPECT_STREQ(error_code(response), "unsupported_method");
}

TEST(FlutterLocalAuthenticationPlugin, UnknownAuthenticationMethodIsAnArgumentError)
{
  for (const char *method : {"canAuthenticate", "getAvailability", "authenticate"})
  {
    g_autoptr(FlValue) args = method_args("somethingNew");
    g_autoptr(FlMethodResponse) response = flutter_local_authentication_plugin_handle(method, args);
    EXPECT_STREQ(error_code(response), "invalid_arguments");
  }
}

TEST(FlutterLocalAuthenticationPlugin, CancelAuthenticationIsNotSupported)
{
  g_autoptr(FlMethodResponse) response = flutter_local_authentication_plugin_handle("cancelAuthentication", nullptr);
  EXPECT_FALSE(fl_value_get_bool(success_value(response)));
}

TEST(FlutterLocalAuthenticationPlugin, UnknownMethodCallIsNotImplemented)
{
  g_autoptr(FlMethodResponse) response = flutter_local_authentication_plugin_handle("getPlatformVersion", nullptr);
  EXPECT_TRUE(FL_IS_METHOD_NOT_IMPLEMENTED_RESPONSE(response));
}
