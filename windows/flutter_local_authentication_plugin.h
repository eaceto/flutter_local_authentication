#ifndef FLUTTER_PLUGIN_FLUTTER_LOCAL_AUTHENTICATION_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_LOCAL_AUTHENTICATION_PLUGIN_H_

#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <cstdint>
#include <functional>
#include <memory>
#include <string>

namespace flutter_local_authentication {

// Marshals work from WinRT completion handlers (which run on the thread pool)
// back to the platform thread that created the plugin.
class PlatformTaskQueue;

class FlutterLocalAuthenticationPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  // |registrar| gives access to the Flutter view, used to show the Windows
  // Hello prompt. Without it, authenticate fails with notAvailable.
  explicit FlutterLocalAuthenticationPlugin(
      flutter::PluginRegistrarWindows *registrar = nullptr);

  virtual ~FlutterLocalAuthenticationPlugin();

  // Disallow copy and assign.
  FlutterLocalAuthenticationPlugin(const FlutterLocalAuthenticationPlugin&) = delete;
  FlutterLocalAuthenticationPlugin& operator=(const FlutterLocalAuthenticationPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  // Returns the top-level window that hosts the Flutter view, if any. Looked
  // up on every call because the runner parents the view after registering
  // plugins, and apps may reparent it later.
  HWND GetTopLevelWindow() const;

  flutter::PluginRegistrarWindows *registrar_;
  std::shared_ptr<PlatformTaskQueue> task_queue_;
  std::function<void()> cancel_authentication_;
  bool cancellation_requested_ = false;
  uint64_t authentication_id_ = 0;
  std::string localization_reason_ = "Authentication is required.";
};

}  // namespace flutter_local_authentication

#endif  // FLUTTER_PLUGIN_FLUTTER_LOCAL_AUTHENTICATION_PLUGIN_H_
