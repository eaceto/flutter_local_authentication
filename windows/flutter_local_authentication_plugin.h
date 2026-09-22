#ifndef FLUTTER_PLUGIN_FLUTTER_LOCAL_AUTHENTICATION_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_LOCAL_AUTHENTICATION_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <functional>
#include <memory>
#include <string>

namespace flutter_local_authentication {

class FlutterLocalAuthenticationPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterLocalAuthenticationPlugin();

  virtual ~FlutterLocalAuthenticationPlugin();

  // Disallow copy and assign.
  FlutterLocalAuthenticationPlugin(const FlutterLocalAuthenticationPlugin&) = delete;
  FlutterLocalAuthenticationPlugin& operator=(const FlutterLocalAuthenticationPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  HWND window_handle_ = nullptr;
  std::function<void()> cancel_authentication_;
  bool cancellation_requested_ = false;
  std::string localization_reason_ = "Authentication is required.";
};

}  // namespace flutter_local_authentication

#endif  // FLUTTER_PLUGIN_FLUTTER_LOCAL_AUTHENTICATION_PLUGIN_H_
