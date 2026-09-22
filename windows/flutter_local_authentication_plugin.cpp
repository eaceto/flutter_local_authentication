#include "flutter_local_authentication_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Security.Credentials.UI.h>
#include <winrt/base.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <string>

namespace flutter_local_authentication {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResult;
using winrt::Windows::Foundation::AsyncStatus;
using winrt::Windows::Security::Credentials::UI::UserConsentVerificationResult;
using winrt::Windows::Security::Credentials::UI::UserConsentVerifier;
using winrt::Windows::Security::Credentials::UI::UserConsentVerifierAvailability;

constexpr char kAuthenticationError[] = "authentication_error";

// Desktop Windows apps use this WinRT interop interface to associate the
// Windows Hello prompt with their top-level window.
struct __declspec(uuid("39E050C3-4E74-441A-8DC0-B81104DF949C"))
    IUserConsentVerifierInterop : IInspectable {
  virtual HRESULT STDMETHODCALLTYPE RequestVerificationForWindowAsync(
      HWND app_window, HSTRING message, IInspectable **operation) = 0;
};

std::shared_ptr<MethodResult<EncodableValue>> ShareResult(
    std::unique_ptr<MethodResult<EncodableValue>> result) {
  return std::shared_ptr<MethodResult<EncodableValue>>(std::move(result));
}

std::string AvailabilityKey(UserConsentVerifierAvailability availability) {
  switch (availability) {
    case UserConsentVerifierAvailability::Available:
      return "available";
    case UserConsentVerifierAvailability::NotConfiguredForUser:
      return "notEnrolled";
    case UserConsentVerifierAvailability::DeviceBusy:
    case UserConsentVerifierAvailability::DeviceNotPresent:
    case UserConsentVerifierAvailability::DisabledByPolicy:
    default:
      return "notAvailable";
  }
}

std::string ErrorReason(UserConsentVerificationResult verification_result) {
  switch (verification_result) {
    case UserConsentVerificationResult::Canceled:
      return "userCanceled";
    case UserConsentVerificationResult::RetriesExhausted:
      return "lockedOut";
    case UserConsentVerificationResult::NotConfiguredForUser:
      return "notEnrolled";
    case UserConsentVerificationResult::DeviceNotPresent:
    case UserConsentVerificationResult::DisabledByPolicy:
    case UserConsentVerificationResult::DeviceBusy:
      return "notAvailable";
    case UserConsentVerificationResult::Verified:
    default:
      return "failed";
  }
}

void ReplyAuthenticationError(
    const std::shared_ptr<MethodResult<EncodableValue>> &result,
    UserConsentVerificationResult verification_result) {
  const auto reason = ErrorReason(verification_result);
  EncodableMap details;
  details[EncodableValue("reason")] = EncodableValue(reason);
  const EncodableValue details_value(details);
  result->Error(kAuthenticationError, reason, &details_value);
}

bool IsKnownAuthenticationMethod(const EncodableValue *arguments) {
  if (arguments == nullptr || !std::holds_alternative<flutter::EncodableMap>(*arguments)) {
    return true;
  }
  const auto &map = std::get<flutter::EncodableMap>(*arguments);
  const auto method = map.find(EncodableValue("method"));
  if (method == map.end() || !std::holds_alternative<std::string>(method->second)) {
    return true;
  }
  const auto &name = std::get<std::string>(method->second);
  return name == "biometricsOnly" || name == "biometricsOrDeviceCredential" ||
         name == "deviceCredentialOnly";
}

}  // namespace

// static
void FlutterLocalAuthenticationPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "flutter_local_authentication",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FlutterLocalAuthenticationPlugin>();
  if (auto view = registrar->GetView()) {
    plugin->window_handle_ = GetAncestor(view->GetNativeWindow(), GA_ROOT);
  }

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FlutterLocalAuthenticationPlugin::FlutterLocalAuthenticationPlugin() {}

FlutterLocalAuthenticationPlugin::~FlutterLocalAuthenticationPlugin() {}

void FlutterLocalAuthenticationPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getPlatformVersion") == 0) {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) {
      version_stream << "10+";
    } else if (IsWindows8OrGreater()) {
      version_stream << "8";
    } else if (IsWindows7OrGreater()) {
      version_stream << "7";
    }
    result->Success(flutter::EncodableValue(version_stream.str()));
  } else if (method_call.method_name().compare("canAuthenticate") == 0 ||
             method_call.method_name().compare("getAvailability") == 0) {
    if (!IsKnownAuthenticationMethod(method_call.arguments())) {
      result->Error("invalid_arguments", "Unknown authentication method.", nullptr);
      return;
    }
    auto shared_result = ShareResult(std::move(result));
    UserConsentVerifier::CheckAvailabilityAsync().Completed(
        [shared_result, is_boolean = method_call.method_name().compare("canAuthenticate") == 0](
            auto operation, AsyncStatus status) {
          if (status != AsyncStatus::Completed) {
            if (is_boolean) {
              shared_result->Success(EncodableValue(false));
            } else {
              shared_result->Success(EncodableValue("notAvailable"));
            }
            return;
          }
          const auto availability = operation.GetResults();
          if (is_boolean) {
            shared_result->Success(EncodableValue(
                availability == UserConsentVerifierAvailability::Available));
          } else {
            shared_result->Success(EncodableValue(AvailabilityKey(availability)));
          }
        });
  } else if (method_call.method_name().compare("getBiometryType") == 0) {
    // Windows does not expose whether Hello is configured for face, iris, or
    // fingerprint through UserConsentVerifier.
    result->Success(EncodableValue("multiple"));
  } else if (method_call.method_name().compare("cancelAuthentication") == 0) {
    if (cancel_authentication_) {
      cancellation_requested_ = true;
      cancel_authentication_();
      cancel_authentication_ = nullptr;
      result->Success(EncodableValue(true));
    } else {
      result->Success(EncodableValue(false));
    }
  } else if (method_call.method_name().compare("authenticate") == 0) {
    if (!IsKnownAuthenticationMethod(method_call.arguments())) {
      result->Error("invalid_arguments", "Unknown authentication method.", nullptr);
      return;
    }
    auto shared_result = ShareResult(std::move(result));
    if (window_handle_ == nullptr) {
      ReplyAuthenticationError(shared_result,
                               UserConsentVerificationResult::DeviceNotPresent);
      return;
    }
    const auto message = winrt::to_hstring(localization_reason_);
    auto factory = winrt::get_activation_factory<UserConsentVerifier,
                                                  IUserConsentVerifierInterop>();
    winrt::IInspectable operation_inspectable;
    const HRESULT request_result =
        factory->RequestVerificationForWindowAsync(
        window_handle_, winrt::get_abi(message),
            operation_inspectable.put());
    if (FAILED(request_result)) {
      ReplyAuthenticationError(shared_result,
                               UserConsentVerificationResult::DeviceNotPresent);
      return;
    }
    auto operation = operation_inspectable.as<
        winrt::Windows::Foundation::IAsyncOperation<UserConsentVerificationResult>>();
    cancellation_requested_ = false;
    cancel_authentication_ = [operation]() { operation.Cancel(); };
    operation.Completed([this, shared_result](auto operation, AsyncStatus status) {
      cancel_authentication_ = nullptr;
      if (status == AsyncStatus::Completed &&
          operation.GetResults() == UserConsentVerificationResult::Verified) {
        shared_result->Success(EncodableValue(true));
      } else if (status == AsyncStatus::Canceled) {
        const auto reason = cancellation_requested_ ? "systemCanceled" : "userCanceled";
        EncodableMap details;
        details[EncodableValue("reason")] = EncodableValue(reason);
        const EncodableValue details_value(details);
        shared_result->Error(kAuthenticationError, reason, &details_value);
      } else if (status == AsyncStatus::Completed) {
        ReplyAuthenticationError(shared_result, operation.GetResults());
      } else {
        ReplyAuthenticationError(shared_result,
                                 UserConsentVerificationResult::DeviceBusy);
      }
    });
  } else if (method_call.method_name().compare(
                 "setTouchIDAuthenticationAllowableReuseDuration") == 0) {
    const auto *arguments = method_call.arguments();
    double duration = 0.0;
    if (arguments != nullptr &&
        std::holds_alternative<flutter::EncodableMap>(*arguments)) {
      const auto &map = std::get<flutter::EncodableMap>(*arguments);
      const auto value = map.find(EncodableValue("duration"));
      if (value != map.end() && std::holds_alternative<double>(value->second)) {
        duration = std::get<double>(value->second);
      }
    }
    result->Success(EncodableValue(duration));
  } else if (method_call.method_name().compare(
                 "getTouchIDAuthenticationAllowableReuseDuration") == 0) {
    result->Success(EncodableValue(0.0));
  } else if (method_call.method_name().compare("setLocalizationModel") == 0) {
    const auto *arguments = method_call.arguments();
    if (arguments != nullptr &&
        std::holds_alternative<flutter::EncodableMap>(*arguments)) {
      const auto &map = std::get<flutter::EncodableMap>(*arguments);
      const auto reason = map.find(EncodableValue("promptDialogReason"));
      if (reason != map.end() &&
          std::holds_alternative<std::string>(reason->second)) {
        localization_reason_ = std::get<std::string>(reason->second);
      }
    }
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace flutter_local_authentication
