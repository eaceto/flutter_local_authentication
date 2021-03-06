#include "include/flutter_local_authentication/flutter_local_authentication_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <unistd.h>

#include <cstring>

#define flutter_local_authentication_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), flutter_local_authentication_plugin_get_type(), \
                              FlutterLocalAuthenticationPlugin))

#define FLUTTER_FINGERPINT_FPRINTD_VERIFY "fprintd-verify"

struct _FlutterLocalAuthenticationPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(FlutterLocalAuthenticationPlugin, flutter_local_authentication_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void flutter_local_authentication_plugin_handle_method_call(
    FlutterLocalAuthenticationPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "supportsAuthentication") == 0) {
    gboolean hasAccess = access(FLUTTER_FINGERPINT_FPRINTD_VERIFY, X_OK);
    g_autoptr(FlValue) result = fl_value_new_bool(hasAccess);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

// Other Flutter methods for managing plugins
static void flutter_local_authentication_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(flutter_local_authentication_plugin_parent_class)->dispose(object);
}

static void flutter_local_authentication_plugin_class_init(FlutterLocalAuthenticationPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = flutter_local_authentication_plugin_dispose;
}

static void flutter_local_authentication_plugin_init(FlutterLocalAuthenticationPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  FlutterLocalAuthenticationPlugin* plugin = flutter_local_authentication_PLUGIN(user_data);
  flutter_local_authentication_plugin_handle_method_call(plugin, method_call);
}

void flutter_local_authentication_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  FlutterLocalAuthenticationPlugin* plugin = flutter_local_authentication_PLUGIN(
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
