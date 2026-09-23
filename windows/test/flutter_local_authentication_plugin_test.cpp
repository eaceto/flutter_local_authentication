#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <gtest/gtest.h>
#include <windows.h>

#include <functional>
#include <memory>
#include <optional>
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

// Runs the message loop of the current (platform) thread until |done| returns
// true or a timeout expires, so that replies posted from WinRT completion
// handlers are delivered.
bool PumpMessagesUntil(const std::function<bool()> &done) {
  const ULONGLONG deadline = GetTickCount64() + 10000;
  while (!done() && GetTickCount64() < deadline) {
    MSG message;
    while (PeekMessageW(&message, nullptr, 0, 0, PM_REMOVE)) {
      TranslateMessage(&message);
      DispatchMessageW(&message);
    }
    Sleep(10);
  }
  return done();
}

std::unique_ptr<EncodableValue> MethodArguments(const std::string &method) {
  return std::make_unique<EncodableValue>(
      EncodableMap{{EncodableValue("method"), EncodableValue(method)}});
}

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
  std::optional<std::string> biometry_type;
  plugin.HandleMethodCall(
      MethodCall("getBiometryType", std::make_unique<EncodableValue>()),
      std::make_unique<MethodResultFunctions<>>(
          [&biometry_type](const EncodableValue* result) {
            biometry_type = std::get<std::string>(*result);
          },
          nullptr, nullptr));

  ASSERT_TRUE(PumpMessagesUntil([&] { return biometry_type.has_value(); }));
  // Depends on whether Windows Hello is set up on the host.
  EXPECT_TRUE(*biometry_type == "multiple" || *biometry_type == "none");
}

TEST(FlutterLocalAuthenticationPlugin, GetAvailabilityRepliesOnPlatformThread) {
  FlutterLocalAuthenticationPlugin plugin;
  const DWORD platform_thread = GetCurrentThreadId();
  std::optional<std::string> availability;
  DWORD reply_thread = 0;
  plugin.HandleMethodCall(
      MethodCall("getAvailability", MethodArguments("biometricsOnly")),
      std::make_unique<MethodResultFunctions<>>(
          [&](const EncodableValue* result) {
            availability = std::get<std::string>(*result);
            reply_thread = GetCurrentThreadId();
          },
          nullptr, nullptr));

  ASSERT_TRUE(PumpMessagesUntil([&] { return availability.has_value(); }));
  EXPECT_EQ(reply_thread, platform_thread);
  EXPECT_TRUE(*availability == "available" || *availability == "notEnrolled" ||
              *availability == "notAvailable");
}

TEST(FlutterLocalAuthenticationPlugin, RejectsUnknownAuthenticationMethod) {
  FlutterLocalAuthenticationPlugin plugin;
  std::string error_code;
  plugin.HandleMethodCall(
      MethodCall("canAuthenticate", MethodArguments("retinaScan")),
      std::make_unique<MethodResultFunctions<>>(
          nullptr,
          [&error_code](const std::string& code, const std::string&,
                        const EncodableValue*) { error_code = code; },
          nullptr));

  EXPECT_EQ(error_code, "invalid_arguments");
}

TEST(FlutterLocalAuthenticationPlugin, AuthenticateWithoutViewIsNotAvailable) {
  FlutterLocalAuthenticationPlugin plugin;
  std::string error_code;
  std::string reason;
  plugin.HandleMethodCall(
      MethodCall("authenticate", MethodArguments("biometricsOnly")),
      std::make_unique<MethodResultFunctions<>>(
          nullptr,
          [&](const std::string& code, const std::string&,
              const EncodableValue* details) {
            error_code = code;
            const auto& map = std::get<EncodableMap>(*details);
            reason = std::get<std::string>(map.at(EncodableValue("reason")));
          },
          nullptr));

  EXPECT_EQ(error_code, "authentication_error");
  EXPECT_EQ(reason, "notAvailable");
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
