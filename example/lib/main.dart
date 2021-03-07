import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_local_authentication/flutter_local_authentication.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _supportsAuthentication = false;

  @override
  void initState() {
    super.initState();
    initSupportAuthenticationState();
  }

  Future<void> initSupportAuthenticationState() async {
    bool supportsLocalAuthentication =
        await FlutterLocalAuthentication.supportsAuthentication;

    if (!mounted) return;
    setState(() {
      _supportsAuthentication = supportsLocalAuthentication;
    });
  }

  void authenticate() async {
    FlutterLocalAuthentication.authenticate().then((authenticated) {
      String result = 'Authenticated: $authenticated';
      debugPrint(result);
    }).catchError((error) {
      String result = 'Exception: $error';
      debugPrint(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Container(
          margin: EdgeInsets.all(20.0),
          child: ListView(
            scrollDirection: Axis.vertical,
            children: <Widget>[
              Text('Local Authentication: $_supportsAuthentication\n'),
              TextButton(
                child: Text('Authenticated'),
                onPressed: authenticate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
