#include "flutter_local_authentication_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>
#include <inspectable.h>
#include <winstring.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Security.Credentials.UI.h>
#include <winrt/base.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <mutex>
#include <optional>
#include <queue>
#include <sstream>
#include <string>
#include <utility>

// Base address of the module (plugin DLL or test executable) this file is
// linked into, used to register the task queue window class.
extern "C" IMAGE_DOS_HEADER __ImageBase;

namespace flutter_local_authentication {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using flutter::MethodResult;
using winrt::Windows::Foundation::AsyncStatus;
using winrt::Windows::Foundation::IAsyncOperation;
using winrt::Windows::Security::Credentials::UI::UserConsentVerificationResult;
using winrt::Windows::Security::Credentials::UI::UserConsentVerifier;
using winrt::Windows::Security::Credentials::UI::UserConsentVerifierAvailability;

constexpr char kAuthenticationError[] = "authentication_error";
constexpr wchar_t kTaskQueueWindowClass[] =
    L"FlutterLocalAuthenticationPluginTaskQueue";
constexpr UINT kRunTasksMessage = WM_APP + 1;

// Desktop Windows apps use this WinRT interop interface to associate the
// Windows Hello prompt with their top-level window. Mirrors the declaration in
// the Windows SDK's UserConsentVerifierInterop.h, which is not available in
// every SDK version.
struct __declspec(uuid("39E050C3-4E74-441A-8DC0-B81104DF949C"))
    IUserConsentVerifierInterop : IInspectable {
  virtual HRESULT STDMETHODCALLTYPE RequestVerificationForWindowAsync(
      HWND app_window, HSTRING message, REFIID riid,
      void **async_operation) = 0;
};

}  // namespace

// A message-only window owned by the platform thread. Tasks posted from any
// thread are run by that thread's message loop.
class PlatformTaskQueue {
 public:
  PlatformTaskQueue() {
    const auto instance = reinterpret_cast<HINSTANCE>(&__ImageBase);
    WNDCLASSEXW window_class{};
    window_class.cbSize = sizeof(window_class);
    window_class.lpfnWndProc = &PlatformTaskQueue::WindowProc;
    window_class.hInstance = instance;
    window_class.lpszClassName = kTaskQueueWindowClass;
    // Fails harmlessly with ERROR_CLASS_ALREADY_EXISTS for later instances.
    RegisterClassExW(&window_class);
    window_ = CreateWindowExW(0, kTaskQueueWindowClass, L"", 0, 0, 0, 0, 0,
                              HWND_MESSAGE, nullptr, instance, nullptr);
    if (window_ != nullptr) {
      SetWindowLongPtrW(window_, GWLP_USERDATA,
                        reinterpret_cast<LONG_PTR>(this));
    }
  }

  ~PlatformTaskQueue() { Close(); }

  PlatformTaskQueue(const PlatformTaskQueue &) = delete;
  PlatformTaskQueue &operator=(const PlatformTaskQueue &) = delete;

  // May be called from any thread. Tasks posted after Close() are dropped.
  void Post(std::function<void()> task) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (window_ == nullptr) {
      return;
    }
    tasks_.push(std::move(task));
    PostMessageW(window_, kRunTasksMessage, 0, 0);
  }

  // Must be called on the platform thread.
  void Close() {
    HWND window;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      window = window_;
      window_ = nullptr;
      tasks_ = {};
    }
    if (window != nullptr) {
      DestroyWindow(window);
    }
  }

 private:
  static LRESULT CALLBACK WindowProc(HWND window, UINT message, WPARAM wparam,
                                     LPARAM lparam) {
    if (message == kRunTasksMessage) {
      auto *queue = reinterpret_cast<PlatformTaskQueue *>(
          GetWindowLongPtrW(window, GWLP_USERDATA));
      if (queue != nullptr) {
        queue->RunTasks();
      }
      return 0;
    }
    return DefWindowProcW(window, message, wparam, lparam);
  }

  void RunTasks() {
    std::queue<std::function<void()>> tasks;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      std::swap(tasks, tasks_);
    }
    while (!tasks.empty()) {
      tasks.front()();
      tasks.pop();
    }
  }

  std::mutex mutex_;
  HWND window_ = nullptr;
  std::queue<std::function<void()>> tasks_;
};

namespace {

using AvailabilityCallback =
    std::function<void(std::optional<UserConsentVerifierAvailability>)>;

std::shared_ptr<MethodResult<EncodableValue>> ShareResult(
    std::unique_ptr<MethodResult<EncodableValue>> result) {
  return std::shared_ptr<MethodResult<EncodableValue>>(std::move(result));
}

// Checks whether Windows Hello can be used, and calls |callback| on the
// platform thread. The availability is empty when it could not be checked.
void CheckAvailability(const std::shared_ptr<PlatformTaskQueue> &task_queue,
                       AvailabilityCallback callback) {
  try {
    UserConsentVerifier::CheckAvailabilityAsync().Completed(
        [callback, task_queue](const auto &operation, AsyncStatus status) {
          std::optional<UserConsentVerifierAvailability> availability;
          if (status == AsyncStatus::Completed) {
            availability = operation.GetResults();
          }
          task_queue->Post(
              [callback, availability]() { callback(availability); });
        });
  } catch (const winrt::hresult_error &) {
    callback(std::nullopt);
  }
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
    const std::string &reason) {
  EncodableMap details;
  details[EncodableValue("reason")] = EncodableValue(reason);
  const EncodableValue details_value(details);
  result->Error(kAuthenticationError, reason, details_value);
}

void ReplyAuthenticationError(
    const std::shared_ptr<MethodResult<EncodableValue>> &result,
    UserConsentVerificationResult verification_result) {
  ReplyAuthenticationError(result, ErrorReason(verification_result));
}

bool IsKnownAuthenticationMethod(const EncodableValue *arguments) {
  if (arguments == nullptr || !std::holds_alternative<EncodableMap>(*arguments)) {
    return true;
  }
  const auto &map = std::get<EncodableMap>(*arguments);
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

  auto plugin = std::make_unique<FlutterLocalAuthenticationPlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FlutterLocalAuthenticationPlugin::FlutterLocalAuthenticationPlugin(
    flutter::PluginRegistrarWindows *registrar)
    : registrar_(registrar),
      task_queue_(std::make_shared<PlatformTaskQueue>()) {}

FlutterLocalAuthenticationPlugin::~FlutterLocalAuthenticationPlugin() {
  // Pending tasks capture `this`; make sure none of them can run anymore.
  // WinRT handlers still in flight hold their own reference to the queue.
  task_queue_->Close();
  if (cancel_authentication_) {
    try {
      cancel_authentication_();
    } catch (const winrt::hresult_error &) {
    }
  }
}

HWND FlutterLocalAuthenticationPlugin::GetTopLevelWindow() const {
  if (registrar_ == nullptr) {
    return nullptr;
  }
  auto *view = registrar_->GetView();
  if (view == nullptr) {
    return nullptr;
  }
  const HWND root = GetAncestor(view->GetNativeWindow(), GA_ROOT);
  // Until the runner parents the view, it is not hosted by a top-level window.
  if (root == nullptr || (GetWindowLongPtrW(root, GWL_STYLE) & WS_CHILD) != 0) {
    return nullptr;
  }
  return root;
}

void FlutterLocalAuthenticationPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto &method_name = method_call.method_name();
  if (method_name == "getPlatformVersion") {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) {
      version_stream << "10+";
    } else if (IsWindows8OrGreater()) {
      version_stream << "8";
    } else if (IsWindows7OrGreater()) {
      version_stream << "7";
    }
    result->Success(EncodableValue(version_stream.str()));
  } else if (method_name == "canAuthenticate" ||
             method_name == "getAvailability") {
    if (!IsKnownAuthenticationMethod(method_call.arguments())) {
      result->Error("invalid_arguments", "Unknown authentication method.");
      return;
    }
    auto shared_result = ShareResult(std::move(result));
    const bool is_boolean = method_name == "canAuthenticate";
    CheckAvailability(task_queue_, [shared_result, is_boolean](
                                       std::optional<UserConsentVerifierAvailability>
                                           availability) {
      if (is_boolean) {
        shared_result->Success(EncodableValue(
            availability == UserConsentVerifierAvailability::Available));
      } else {
        shared_result->Success(EncodableValue(
            availability ? AvailabilityKey(*availability) : "notAvailable"));
      }
    });
  } else if (method_name == "getBiometryType") {
    // Windows does not expose whether Hello is configured for face, iris, or
    // fingerprint through UserConsentVerifier.
    auto shared_result = ShareResult(std::move(result));
    CheckAvailability(task_queue_, [shared_result](
                                       std::optional<UserConsentVerifierAvailability>
                                           availability) {
      shared_result->Success(EncodableValue(
          availability == UserConsentVerifierAvailability::Available
              ? "multiple"
              : "none"));
    });
  } else if (method_name == "cancelAuthentication") {
    if (cancel_authentication_) {
      cancellation_requested_ = true;
      auto cancel = std::move(cancel_authentication_);
      cancel_authentication_ = nullptr;
      try {
        cancel();
        result->Success(EncodableValue(true));
      } catch (const winrt::hresult_error &) {
        result->Success(EncodableValue(false));
      }
    } else {
      result->Success(EncodableValue(false));
    }
  } else if (method_name == "authenticate") {
    if (!IsKnownAuthenticationMethod(method_call.arguments())) {
      result->Error("invalid_arguments", "Unknown authentication method.");
      return;
    }
    auto shared_result = ShareResult(std::move(result));
    const HWND window = GetTopLevelWindow();
    if (window == nullptr) {
      ReplyAuthenticationError(shared_result, "notAvailable");
      return;
    }
    IAsyncOperation<UserConsentVerificationResult> operation{nullptr};
    try {
      const auto message = winrt::to_hstring(localization_reason_);
      const auto factory =
          winrt::get_activation_factory<UserConsentVerifier,
                                        IUserConsentVerifierInterop>();
      const winrt::guid operation_iid = winrt::guid_of<decltype(operation)>();
      winrt::check_hresult(factory->RequestVerificationForWindowAsync(
          window, static_cast<HSTRING>(winrt::get_abi(message)),
          reinterpret_cast<const IID &>(operation_iid),
          winrt::put_abi(operation)));
    } catch (const winrt::hresult_error &) {
      ReplyAuthenticationError(shared_result, "notAvailable");
      return;
    }
    // Identifies this request so a stale completion does not clear the
    // cancel handler of a newer one.
    const auto authentication_id = ++authentication_id_;
    cancellation_requested_ = false;
    cancel_authentication_ = [operation]() { operation.Cancel(); };
    operation.Completed([this, shared_result, authentication_id,
                         task_queue = task_queue_](const auto &completed,
                                                   AsyncStatus status) {
      std::optional<UserConsentVerificationResult> verification_result;
      if (status == AsyncStatus::Completed) {
        verification_result = completed.GetResults();
      }
      // `this` is only dereferenced on the platform thread, and the queue
      // drops tasks once the plugin has been destroyed.
      task_queue->Post([this, shared_result, authentication_id, status,
                        verification_result]() {
        const bool is_current = authentication_id == authentication_id_;
        if (is_current) {
          cancel_authentication_ = nullptr;
        }
        if (verification_result == UserConsentVerificationResult::Verified) {
          shared_result->Success(EncodableValue(true));
        } else if (status == AsyncStatus::Canceled) {
          ReplyAuthenticationError(
              shared_result, is_current && cancellation_requested_
                                 ? "systemCanceled"
                                 : "userCanceled");
        } else if (verification_result) {
          ReplyAuthenticationError(shared_result, *verification_result);
        } else {
          ReplyAuthenticationError(shared_result, "notAvailable");
        }
      });
    });
  } else if (method_name == "setTouchIDAuthenticationAllowableReuseDuration") {
    const auto *arguments = method_call.arguments();
    double duration = 0.0;
    if (arguments != nullptr && std::holds_alternative<EncodableMap>(*arguments)) {
      const auto &map = std::get<EncodableMap>(*arguments);
      const auto value = map.find(EncodableValue("duration"));
      if (value != map.end() && std::holds_alternative<double>(value->second)) {
        duration = std::get<double>(value->second);
      }
    }
    result->Success(EncodableValue(duration));
  } else if (method_name == "getTouchIDAuthenticationAllowableReuseDuration") {
    result->Success(EncodableValue(0.0));
  } else if (method_name == "setLocalizationModel") {
    const auto *arguments = method_call.arguments();
    if (arguments != nullptr && std::holds_alternative<EncodableMap>(*arguments)) {
      const auto &map = std::get<EncodableMap>(*arguments);
      const auto reason = map.find(EncodableValue("promptDialogReason"));
      // An empty reason would leave the Windows Hello prompt without a message.
      if (reason != map.end() &&
          std::holds_alternative<std::string>(reason->second) &&
          !std::get<std::string>(reason->second).empty()) {
        localization_reason_ = std::get<std::string>(reason->second);
      }
    }
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace flutter_local_authentication
