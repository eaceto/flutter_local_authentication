#include "include/flutter_local_authentication/flutter_local_authentication_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_local_authentication_plugin.h"

void FlutterLocalAuthenticationPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_local_authentication::FlutterLocalAuthenticationPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
