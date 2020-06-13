import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:thecave/pages/checkout.dart';
import 'package:thecave/pages/dashboard.dart';
import 'package:thecave/pages/detail.dart';
import 'package:thecave/pages/keranjang.dart';
import 'package:thecave/pages/login.dart';
import 'package:thecave/pages/profile.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final PermissionHandler _permissionHandler = PermissionHandler();

  void getPermission() async {
    var result = await _permissionHandler
        .requestPermissions([PermissionGroup.camera, PermissionGroup.storage]);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    getPermission();

    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);

        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: MaterialApp(
        title: 'The Cave',
        theme: ThemeData(
          accentColor: Colors.blue,
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => Login(),
          '/dashboard': (context) => Dashboard(),
          '/profile': (context) => Profile(),
          '/cart': (context) => Keranjang(),
          '/checkout': (context) => Checkout(),
          '/detail': (context) => DetailTransaksi(),
        },
      ),
    );
  }
}
