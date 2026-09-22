#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <gtest/gtest.h>
#include <windows.h>

#include <memory>
#include <string>
#include <variant>

#include "flutter_local_authentication_plugin.h"

namespace flutter_local_authentication {
namespace test {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResultFunctions;

}  // namespace

TEST(FlutterLocalAuthenticationPlugin, GetPlatformVersion) {
  FlutterLocalAuthenticationPlugin plugin;
  // Save the reply value from the success callback.
  std::string result_string;
  plugin.HandleMethodCall(
      MethodCall("getPlatformVersion", std::make_unique<EncodableValue>()),
      std::make_unique<MethodResultFunctions<>>(
          [&result_string](const EncodableValue* result) {
            result_string = std::get<std::string>(*result);
          },
          nullptr, nullptr));

  // Since the exact string varies by host, just ensure that it's a string
  // with the expected format.
  EXPECT_TRUE(result_string.rfind("Windows ", 0) == 0);
}

TEST(FlutterLocalAuthenticationPlugin, ReportsWindowsHelloBiometryType) {
  FlutterLocalAuthenticationPlugin plugin;
  std::string biometry_type;
  plugin.HandleMethodCall(
      MethodCall("getBiometryType", std::make_unique<EncodableValue>()),
      std::make_unique<MethodResultFunctions<>>(
          [&biometry_type](const EncodableValue* result) {
            biometry_type = std::get<std::string>(*result);
          },
          nullptr, nullptr));

  EXPECT_EQ(biometry_type, "multiple");
}

TEST(FlutterLocalAuthenticationPlugin, CancelWithoutAuthenticationReturnsFalse) {
  FlutterLocalAuthenticationPlugin plugin;
  bool canceled = true;
  plugin.HandleMethodCall(
      MethodCall("cancelAuthentication", std::make_unique<EncodableValue>()),
      std::make_unique<MethodResultFunctions<>>(
          [&canceled](const EncodableValue* result) {
            canceled = std::get<bool>(*result);
          },
          nullptr, nullptr));

  EXPECT_FALSE(canceled);
}

}  // namespace test
}  // namespace flutter_local_authentication
