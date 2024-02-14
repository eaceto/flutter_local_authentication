// Author: Ezequiel (Kimi) Aceto
// Email: ezequiel.aceto@gmail.com
// Website: https://eaceto.dev

#include "include/flutter_local_authentication/flutter_local_authentication_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <unistd.h>

#include <cstring>

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

// Function to handle method calls from Flutter
static void flutter_local_authentication_plugin_handle_method_call(
    FlutterLocalAuthenticationPlugin *self,
    FlMethodCall *method_call)
{
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar *method = fl_method_call_get_name(method_call);

  if (strcmp(method, "canAuthenticate") == 0)
  {
    // Execute the "fprintd-list $USER" command and check the return status
    gboolean hasAccess = system(LINUX_FPRINTD_LIST) == 0;
    g_autoptr(FlValue) result = fl_value_new_bool(hasAccess);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  }
  else if (strcmp(method, "authenticate") == 0)
  {
    // Execute the "fprintd-verify" command and check the return status
    gboolean hasAccess = system(LINUX_FPRINTD_VERIFY) == 0;

    g_autoptr(FlValue) result = fl_value_new_bool(hasAccess);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  }
  else
  {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

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
