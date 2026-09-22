// Author: Ezequiel (Kimi) Aceto
// Email: ezequiel.aceto@gmail.com
// Website: https://kimi.blog
//
// Functions of the plugin that are exposed for unit tests only.

#include <flutter_linux/flutter_linux.h>

#include "include/flutter_local_authentication/flutter_local_authentication_plugin.h"

// Handles a method call, given its name and arguments, and returns the response.
FlMethodResponse *flutter_local_authentication_plugin_handle(const gchar *method, FlValue *args);
