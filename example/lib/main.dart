import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_authentication/flutter_local_authentication.dart';
import 'package:flutter_local_authentication/localization_model.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'SnackBar Demo',
      home: Scaffold(
        appBar: AppBar(title: const Text('FlutterLocalAuthentication Demo')),
        body: const HomeWidget(),
      ),
    ),
  );
}

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  bool _canAuthenticate = false;
  AuthenticationAvailability? _availability;
  BiometryType? _biometryType;
  AuthenticationMethod _method = AuthenticationMethod.biometricsOnly;
  int _reuseDuration = 0;
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
      cancelButtonTitle: "cancel",
    );
    _flutterLocalAuthenticationPlugin.setLocalizationModel(localization);
  }

  Future<void> checkSupport() async {
    bool canAuthenticate;
    AuthenticationAvailability? availability;
    BiometryType? biometryType;
    try {
      canAuthenticate = await _flutterLocalAuthenticationPlugin.canAuthenticate(
        method: _method,
      );
      // The reason why the user can, or can not, authenticate
      availability = await _flutterLocalAuthenticationPlugin.getAvailability(
        method: _method,
      );
      biometryType = await _flutterLocalAuthenticationPlugin.getBiometryType();
    } on Exception catch (error) {
      debugPrint("Exception checking support. $error");
      canAuthenticate = false;
    }

    setState(() {
      _canAuthenticate = canAuthenticate;
      _availability = availability;
      _biometryType = biometryType;
    });
  }

  Future<void> setReuseDuration(int duration) async {
    final storedDuration = await _flutterLocalAuthenticationPlugin
        .setTouchIDAuthenticationAllowableReuseDuration(duration.toDouble());
    if (!mounted) return;
    setState(() {
      _reuseDuration = storedDuration.toInt();
    });
  }

  void authenticate() async {
    _flutterLocalAuthenticationPlugin
        .authenticate(method: _method)
        .then((authenticated) {
          String result = 'Authenticated: $authenticated';
          debugPrint(result);

          String message = (authenticated == true)
              ? 'LocalAuthentication verified!'
              : 'Could not verify you identity';
          if (!mounted) return;
          final snackBar = SnackBar(content: Text(message));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        })
        .catchError((error) {
          String result = 'Exception: $error';
          debugPrint(result);

          // The reason tells what happened in the same way on every platform
          String message = (error is AuthenticationException)
              ? 'Not authenticated: ${error.reason.name}'
              : 'There was an error performing the authentication...';
          if (!mounted) return;
          final snackBar = SnackBar(content: Text(message));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        });
  }

  void authenticateAndCancel() {
    authenticate();
    // Dismisses the prompt, as an app would do when it moves to the background
    Future.delayed(const Duration(seconds: 3), () async {
      final canceled = await _flutterLocalAuthenticationPlugin
          .cancelAuthentication();
      debugPrint('Prompt canceled: $canceled');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20.0),
      child: ListView(
        scrollDirection: Axis.vertical,
        children: <Widget>[
          DropdownButton<AuthenticationMethod>(
            value: _method,
            isExpanded: true,
            items: AuthenticationMethod.values
                .map(
                  (method) =>
                      DropdownMenuItem(value: method, child: Text(method.name)),
                )
                .toList(),
            onChanged: (method) {
              if (method == null) return;
              setState(() {
                _method = method;
              });
              checkSupport();
            },
          ),
          Text('Supports Authentication: $_canAuthenticate'),
          Text('Availability: ${_availability?.name}'),
          Text('Biometry type: ${_biometryType?.name}\n'),
          Text('Touch ID reuse duration: $_reuseDuration seconds'),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('0 seconds')),
              ButtonSegment(value: 60, label: Text('60 seconds')),
            ],
            selected: {_reuseDuration},
            onSelectionChanged: (selection) {
              setReuseDuration(selection.first);
            },
          ),
          TextButton(
            onPressed: checkSupport,
            child: const Text('Check Support Again'),
          ),
          TextButton(
            onPressed: authenticate,
            child: const Text('Authenticate'),
          ),
          TextButton(
            onPressed: authenticateAndCancel,
            child: const Text('Authenticate and cancel after 3 seconds'),
          ),
        ],
      ),
    );
  }
}
