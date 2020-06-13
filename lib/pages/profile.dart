import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart';
import 'package:thecave/env.dart';
import 'package:thecave/widget/loading.dart';

import 'login.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final Env _env = Env();
  bool _dataReady = false;
  String _username = '';
  String _nama = '';
  String _alamat = '';
  String _telp = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    getDataUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
      ),
      body: Container(
        padding: EdgeInsets.fromLTRB(35, 35, 35, 0),
        child: Column(
          children: <Widget>[
            Container(
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.only(bottom: 50),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                child: _dataReady
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Username',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(_username)
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Nama',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(_nama)
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Alamat',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(_alamat)
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Nomor Telepon',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(_telp)
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Role',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(_role)
                              ],
                            ),
                          ),
                        ],
                      )
                    : CircleLoading()),
            ButtonTheme(
              minWidth: MediaQuery.of(context).size.width,
              height: 40,
              child: RaisedButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0)),
                  color: Colors.cyan,
                  child: Text(
                    'LOGOUT',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    SharedPreferences prop =
                        await SharedPreferences.getInstance();
                    await prop.clear();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }

  void getDataUser() async {
    final prop = await SharedPreferences.getInstance();
    final token = prop.getString('token') ?? '';

    try {
      Response response = await get('${_env.baseURL}/check', headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      }).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);

        setState(() {
          _dataReady = true;
          _username = data['data']['user']['username'];
          _nama = data['data']['user']['nama'];
          _alamat = data['data']['user']['alamat'];
          _telp = data['data']['user']['telp'];
          _role = data['data']['user']['role'];
        });
      }
    } on TimeoutException {
      setState(() {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
          arguments:
              ErrorMessage(errorMessage: "Session expired.\nPlease re-login."),
        );
      });
    } catch (error) {
      print(error);
    }
  }
}
