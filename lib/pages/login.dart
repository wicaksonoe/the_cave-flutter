import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thecave/env.dart';
import 'package:thecave/widget/loading.dart';

class ErrorMessage {
  final String message;
  const ErrorMessage({
    @required String errorMessage,
  }) : message = errorMessage;
}

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = true;
  bool _obscureText = true;
  String _errorMsg = "";

  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    ErrorMessage attrErrorMessage =
        ModalRoute.of(context).settings.arguments ?? null;
    if (attrErrorMessage != null) {
      _errorMsg = attrErrorMessage.message;
    }

    return Scaffold(
      body: Scrollbar(
        child: ListView(
          children: <Widget>[
            Container(
              height: MediaQuery.of(context).size.height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _isLoading
                    ? <Widget>[CircleLoading()]
                    : <Widget>[
                        Text(
                          'TheCave',
                          style: TextStyle(
                            fontSize: 36.0,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(50.0, 35.0, 50.0, 10.0),
                          child: TextFormField(
                            autofocus: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(
                                    color: Colors.white,
                                  )),
                              hintText: 'username',
                            ),
                            controller: _username,
                            onTap: () {
                              setState(() => _errorMsg = "");
                            },
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(50.0, 5.0, 50.0, 10.0),
                          child: TextFormField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              hintText: 'password',
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                                child: Icon(_obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                              ),
                            ),
                            obscureText: _obscureText,
                            controller: _password,
                            onTap: () {
                              setState(() => _errorMsg = "");
                            },
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 15.0, bottom: 45.0),
                          child: Center(
                            child: Text(
                              _errorMsg,
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        ButtonTheme(
                          minWidth: MediaQuery.of(context).size.width - (100),
                          height: 60,
                          child: RaisedButton(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                            color: Colors.cyan,
                            child: Text(
                              'LOGIN',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                              });
                              tryLogin();
                            },
                          ),
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void tryLogin() async {
    try {
      Response response = await post(
        '${Env().baseURL}/login',
        headers: {'Accept': 'application/json'},
        body: {'username': _username.text, 'password': _password.text},
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);

        final prop = await SharedPreferences.getInstance();
        prop.setString('token', data['access_token']);

        Navigator.pushReplacementNamed(context, '/main-menu');
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMsg = 'Kombinasi username dan password salah';
          _isLoading = false;
        });
      }
    } on TimeoutException {
      setState(() {
        _errorMsg = 'TimeoutError: Tidak dapat terhubung dengan server\n'
            'Mohon cek kembali koneksi atau jaringan anda';
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMsg = error.toString();
        _isLoading = false;
      });
    }
  }

  void checkAuth() async {
    final prop = await SharedPreferences.getInstance();
    final token = prop.getString('token') ?? '';

    try {
      Response response = await get('${Env().baseURL}/check', headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      }).timeout(Duration(seconds: 30));

      Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        prop.setString('id_bazar', data['id_bazar']);
        Navigator.pushReplacementNamed(context, '/main-menu');
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } on TimeoutException {
      setState(() {
        _errorMsg =
            'TimeoutError: Tidak dapat terhubung dengan server\nMohon cek kembali koneksi atau jaringan anda';
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMsg = error.toString();
        _isLoading = false;
      });
    }
  }
}
