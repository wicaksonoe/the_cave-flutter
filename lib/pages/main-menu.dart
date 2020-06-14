import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as logger;

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
                    Text("Welcome, xxxx"),
                  ],
                ),
              ),
              MenuButtonWidget(
                innerText: "Toko",
                action: () => pushToToko(context),
              ),
              MenuButtonWidget(
                innerText: "Bazar",
                action: () => pushToBazar(context),
              ),
              MenuButtonWidget(
                innerText: "Logout",
                action: () => logout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuButtonWidget extends StatelessWidget {
  const MenuButtonWidget({
    this.key,
    this.action,
    this.innerText,
  });

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
}

pushToToko(context) {
  logger.log("Toko");
}

pushToBazar(context) {
  // logger.log("Bazar");
  Navigator.pushNamed(context, '/dashboard');
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
