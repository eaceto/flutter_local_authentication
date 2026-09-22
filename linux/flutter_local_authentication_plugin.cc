// Author: Ezequiel (Kimi) Aceto
// Email: ezequiel.aceto@gmail.com
// Website: https://kimi.blog

#include "include/flutter_local_authentication/flutter_local_authentication_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <unistd.h>

#include <cstring>

#include "flutter_local_authentication_plugin_private.h"

// Define the path for the "fprintd-verify" executable
#define LINUX_FPRINTD_VERIFY "fprintd-verify"
// Define the "fprintd-list $USER" command
#define LINUX_FPRINTD_LIST "fprintd-list $USER"

// Macro to cast the plugin object
#define FLUTTER_LOCAL_AUTHENTICATION_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), flutter_local_authentication_plugin_get_type(), \
                              FlutterLocalAuthenticationPlugin))

// Structure for the FlutterLocalAuthenticationPlugin
struct _FlutterLocalAuthenticationPlugin
{
  GObject parent_instance;
};

// Macro for defining the GObject type
G_DEFINE_TYPE(FlutterLocalAuthenticationPlugin, flutter_local_authentication_plugin, g_object_get_type())

/**
 * FlutterLocalAuthenticationPluginClass:
 * @parent_class: The parent class.
 * @dispose: Class method to dispose of the plugin object.
 *
 * Structure representing the class definition for the FlutterLocalAuthenticationPlugin.
 */
struct _FlutterLocalAuthenticationPluginClass
{
  GObjectClass parent_class;
};

// Authentication methods, matching the names of the Dart "AuthenticationMethod" enum
#define AUTHENTICATION_METHOD_BIOMETRICS_ONLY "biometricsOnly"
#define AUTHENTICATION_METHOD_BIOMETRICS_OR_DEVICE_CREDENTIAL "biometricsOrDeviceCredential"
#define AUTHENTICATION_METHOD_DEVICE_CREDENTIAL_ONLY "deviceCredentialOnly"

// Function to read the authentication method from the arguments of a method call.
// Returns "biometricsOnly" when no method is given.
static const gchar *get_authentication_method(FlValue *args)
{
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
  {
    return AUTHENTICATION_METHOD_BIOMETRICS_ONLY;
  }
  FlValue *value = fl_value_lookup_string(args, "method");
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_STRING)
  {
    return AUTHENTICATION_METHOD_BIOMETRICS_ONLY;
  }
  return fl_value_get_string(value);
}

// Function to build the error response for an authentication method that can not be used.
// Only fingerprint authentication (fprintd) is available on Linux.
static FlMethodResponse *authentication_method_error_response_new(const gchar *authentication_method)
{
  if (strcmp(authentication_method, AUTHENTICATION_METHOD_BIOMETRICS_OR_DEVICE_CREDENTIAL) == 0 ||
      strcmp(authentication_method, AUTHENTICATION_METHOD_DEVICE_CREDENTIAL_ONLY) == 0)
  {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "unsupported_method", "Only biometric authentication is supported on Linux.", nullptr));
  }
  return FL_METHOD_RESPONSE(fl_method_error_response_new(
      "invalid_arguments", "Unknown authentication method.", nullptr));
}

// Function to handle a method call, given its name and arguments
FlMethodResponse *flutter_local_authentication_plugin_handle(const gchar *method, FlValue *args)
{
  FlMethodResponse *response = nullptr;

  if (strcmp(method, "canAuthenticate") == 0)
  {
    const gchar *authentication_method = get_authentication_method(args);
    if (strcmp(authentication_method, AUTHENTICATION_METHOD_BIOMETRICS_ONLY) == 0)
    {
      // Execute the "fprintd-list $USER" command and check the return status
      gboolean hasAccess = system(LINUX_FPRINTD_LIST) == 0;
      g_autoptr(FlValue) result = fl_value_new_bool(hasAccess);
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(authentication_method, AUTHENTICATION_METHOD_BIOMETRICS_OR_DEVICE_CREDENTIAL) == 0 ||
             strcmp(authentication_method, AUTHENTICATION_METHOD_DEVICE_CREDENTIAL_ONLY) == 0)
    {
      // Methods that are not supported can not be used to authenticate
      g_autoptr(FlValue) result = fl_value_new_bool(FALSE);
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else
    {
      response = authentication_method_error_response_new(authentication_method);
    }
  }
  else if (strcmp(method, "getAvailability") == 0)
  {
    const gchar *authentication_method = get_authentication_method(args);
    if (strcmp(authentication_method, AUTHENTICATION_METHOD_BIOMETRICS_ONLY) == 0)
    {
      // Execute the "fprintd-list $USER" command and check the return status
      gboolean hasAccess = system(LINUX_FPRINTD_LIST) == 0;
      g_autoptr(FlValue) result = fl_value_new_string(hasAccess ? "available" : "notAvailable");
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(authentication_method, AUTHENTICATION_METHOD_BIOMETRICS_OR_DEVICE_CREDENTIAL) == 0 ||
             strcmp(authentication_method, AUTHENTICATION_METHOD_DEVICE_CREDENTIAL_ONLY) == 0)
    {
      g_autoptr(FlValue) result = fl_value_new_string("unsupportedMethod");
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else
    {
      response = authentication_method_error_response_new(authentication_method);
    }
  }
  else if (strcmp(method, "getBiometryType") == 0)
  {
    // Only fingerprint authentication (fprintd) is available on Linux
    gboolean hasAccess = system(LINUX_FPRINTD_LIST) == 0;
    g_autoptr(FlValue) result = fl_value_new_string(hasAccess ? "fingerprint" : "none");
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  }
  else if (strcmp(method, "cancelAuthentication") == 0)
  {
    // "fprintd-verify" blocks until it finishes, so there is never a prompt to dismiss
    g_autoptr(FlValue) result = fl_value_new_bool(FALSE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  }
  else if (strcmp(method, "authenticate") == 0)
  {
    const gchar *authentication_method = get_authentication_method(args);
    if (strcmp(authentication_method, AUTHENTICATION_METHOD_BIOMETRICS_ONLY) == 0)
    {
      // Execute the "fprintd-verify" command and check the return status
      gboolean hasAccess = system(LINUX_FPRINTD_VERIFY) == 0;

      g_autoptr(FlValue) result = fl_value_new_bool(hasAccess);
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else
    {
      response = authentication_method_error_response_new(authentication_method);
    }
  }
  else
  {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  return response;
}

// Function to handle method calls from Flutter
static void flutter_local_authentication_plugin_handle_method_call(
    FlutterLocalAuthenticationPlugin *self,
    FlMethodCall *method_call)
{
  g_autoptr(FlMethodResponse) response = flutter_local_authentication_plugin_handle(
      fl_method_call_get_name(method_call), fl_method_call_get_args(method_call));
  fl_method_call_respond(method_call, response, nullptr);
}

// Function to dispose of the plugin object
static void flutter_local_authentication_plugin_dispose(GObject *object)
{
  G_OBJECT_CLASS(flutter_local_authentication_plugin_parent_class)->dispose(object);
}

// Function to initialize the class
static void flutter_local_authentication_plugin_class_init(FlutterLocalAuthenticationPluginClass *klass)
{
  G_OBJECT_CLASS(klass)->dispose = flutter_local_authentication_plugin_dispose;
}

// Function to initialize the object
static void flutter_local_authentication_plugin_init(FlutterLocalAuthenticationPlugin *self) {}

// Function to handle method call callback
static void method_call_cb(FlMethodChannel *channel, FlMethodCall *method_call,
                           gpointer user_data)
{
  FlutterLocalAuthenticationPlugin *plugin = FLUTTER_LOCAL_AUTHENTICATION_PLUGIN(user_data);
  flutter_local_authentication_plugin_handle_method_call(plugin, method_call);
}

// Function to register the plugin with the Flutter registrar
void flutter_local_authentication_plugin_register_with_registrar(FlPluginRegistrar *registrar)
{
  FlutterLocalAuthenticationPlugin *plugin = FLUTTER_LOCAL_AUTHENTICATION_PLUGIN(
      g_object_new(flutter_local_authentication_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "flutter_local_authentication",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
