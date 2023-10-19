import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_authentication/flutter_local_authentication.dart';
import 'package:flutter_local_authentication/localization_model.dart';

void main() {
  runApp(MaterialApp(
    title: 'SnackBar Demo',
    home: Scaffold(
      appBar: AppBar(
        title: const Text('FlutterLocalAuthentication Demo'),
      ),
      body: const HomeWidget(),
    ),
  ));
}

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  bool _canAuthenticate = false;
  final _flutterLocalAuthenticationPlugin = FlutterLocalAuthentication();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    if (!mounted) return;
    await checkSupport();

    final localization = LocalizationModel(
        promptDialogTitle: "title for dialog",
        promptDialogReason: "reason for prompting biometric",
        cancelButtonTitle: "cancel"
    );
    _flutterLocalAuthenticationPlugin.setLocalizationModel(localization);
  }

  Future<void> checkSupport() async {
    bool canAuthenticate;
    try {
      canAuthenticate =
          await _flutterLocalAuthenticationPlugin.canAuthenticate();
      await _flutterLocalAuthenticationPlugin
          .setTouchIDAuthenticationAllowableReuseDuration(30);
    } on Exception catch (error) {
      debugPrint("Exception checking support. $error");
      canAuthenticate = false;
    }

    setState(() {
      _canAuthenticate = canAuthenticate;
    });
  }

  void authenticate() async {
    _flutterLocalAuthenticationPlugin.authenticate().then((authenticated) {
      String result = 'Authenticated: $authenticated';
      debugPrint(result);

      String message = (authenticated == true)
          ? 'LocalAuthentication verified!'
          : 'Could not verify you identity';
      final snackBar = SnackBar(content: Text(message));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }).catchError((error) {
      String result = 'Exception: $error';
      debugPrint(result);

      const snackBar = SnackBar(
          content: Text('There was an error performing the authentication...'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20.0),
      child: ListView(
        scrollDirection: Axis.vertical,
        children: <Widget>[
          Text('Supports Authentication: $_canAuthenticate\n'),
          TextButton(
            onPressed: checkSupport,
            child: const Text('Check Support Again'),
          ),
          TextButton(
            onPressed: authenticate,
            child: const Text('Authenticate'),
          ),
        ],
      ),
    );
  }
}
