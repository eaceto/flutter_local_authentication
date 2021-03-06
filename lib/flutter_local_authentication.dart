import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class FlutterLocalAuthentication {
  static const MethodChannel _channel =
      const MethodChannel('flutter_local_authentication');

  static Future<bool> get supportsAuthentication async {
    if (Platform.isLinux || Platform.isMacOS || Platform.isIOS || Platform.isAndroid) {
      return await _channel.invokeMethod('getSupportsAuthentication');
    }
    return false;
  }
}
