import 'dart:convert';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as logger;

import 'package:thecave/env.dart';
import 'package:thecave/pages/login.dart';

class MainMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scrollbar(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(bottom: 60),
                child: Column(
                  children: <Widget>[
                    Text(
                      "The Cave",
                      style: TextStyle(
                        fontSize: 36.0,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              MenuButtonWidget(
                innerText: "Toko",
                action: () => MenuButtonWidget().pushToToko(context),
              ),
              MenuButtonWidget(
                innerText: "Bazar",
                action: () => MenuButtonWidget().pushToBazar(context),
              ),
              MenuButtonWidget(
                innerText: "Logout",
                action: () => MenuButtonWidget().logout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuButtonWidget extends StatelessWidget {
  const MenuButtonWidget({this.key, this.action, this.innerText});

  final Key key;
  final VoidCallback action;
  final String innerText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: ButtonTheme(
        minWidth: MediaQuery.of(context).size.width - 100,
        height: 60,
        child: RaisedButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          color: Colors.cyan,
          child: Text(
            innerText,
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          onPressed: action,
        ),
      ),
    );
  }

  pushToToko(context) {
    Navigator.of(context).pushNamed('/dashboard-toko');
  }

  pushToBazar(context) async {
    final Env _env = Env();
    final prop = await SharedPreferences.getInstance();
    final token = prop.getString('token') ?? '';
    Response response;

    response = await get('${_env.baseURL}/check', headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token'
    }).timeout(Duration(seconds: 30));

    Map<String, dynamic> data = await jsonDecode(response.body);

    if (response.statusCode != 200) {
      switch (response.statusCode) {
        case 401:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
            arguments: ErrorMessage(
                errorMessage: "Session expired.\nPlease re-login."),
          );
          break;

        default:
          logger.log(response.body);
          break;
      }

      return;
    }

    if (data['data']['id_bazar'] == '') {
      logger.log("Anda tidak terdaftar dalam bazar.");
      Flushbar(
        padding: EdgeInsets.fromLTRB(30, 25, 0, 25),
        message: "Anda tidak terdaftar dalam bazar.",
        duration: Duration(seconds: 3),
      )..show(context);
      return;
    } else {
      Navigator.pushNamed(context, '/dashboard');
    }

    // logger.log(token);
    // Navigator.pushNamed(context, '/dashboard');
  }

  logout(context) async {
    SharedPreferences prop = await SharedPreferences.getInstance();
    await prop.clear();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }
}
