import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thecave/env.dart';
import 'package:thecave/pages/detail.dart';
import 'package:thecave/widget/loading.dart';

import 'login.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final Env _env = Env();
  bool _isLoading = true;
  String _idBazar = '';
  Map<String, dynamic> _dataBazar = {
    'nama_bazar': '',
    'tanggal_mulai': '',
    'tanggal_akhir': '',
  };
  Map<String, dynamic> _transaksiBazar = {
    'total_transaksi': '100',
    'data_transaksi': '',
  };

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bazar ${_dataBazar['nama_bazar']}'),
        actions: <Widget>[
          Container(
            margin: EdgeInsets.only(right: 20.0),
            child: IconButton(
              iconSize: 35,
              icon: Icon(
                Icons.person,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/profile').then((_) => getData());
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? CircleLoading()
          : Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      widgetJumlahTransaksi(),
                      widgetTanggalBazar()
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 30, left: 5),
                    child: Text(
                      "History Penjualan",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(top: 10),
                      child: widgetHistoryPenjualan(),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: Visibility(
        visible: !_isLoading,
        child: FloatingActionButton(
          child: Icon(
            Icons.add,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pushNamed(context, '/cart')
              .then((_) => getData()),
        ),
      ),
    );
  }

  Scrollbar widgetHistoryPenjualan() {
    return Scrollbar(
      child: ListView.builder(
        itemCount: _transaksiBazar['data_transaksi'].length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              onTap: () {
                final String kodeTrx = _transaksiBazar['data_transaksi'][index]
                        ['kode_trx']
                    .toString();
                Navigator.pushNamed(
                  context,
                  '/detail',
                  arguments: KodeTransaksi(kodeTrx: kodeTrx),
                ).then((_) => getData());
              },
              title: Text(
                  "kode_trx: ${_transaksiBazar['data_transaksi'][index]['kode_trx']}"),
            ),
          );
        },
      ),
    );
  }

  Container widgetJumlahTransaksi() {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 30,
      height: 150,
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.cyan,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Total Transaksi',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          Text(
            "${_transaksiBazar['total_transaksi']}",
            style: TextStyle(
                fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Container widgetTanggalBazar() {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 30,
      height: 150,
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: Colors.cyan,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Tanggal Mulai',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                Text(
                  "${_dataBazar['tanggal_mulai']}",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          ),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Tanggal Akhir',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                Text(
                  "${_dataBazar['tanggal_akhir']}",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> getData() async {
    _isLoading = true;
    final prop = await SharedPreferences.getInstance();
    final token = prop.getString('token') ?? '';

    try {
      Response response;

      do {
        // Proses get id_bazar berdasarkan token
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
              showErrorMessage(response.body);
              break;
          }
          return;
        }

        // redirect langsung ke profile kalo tidak terdaftar di bazar manapun
        if (data['data']['id_bazar'] == '') {
          Navigator.pushReplacementNamed(context, '/profile')
              .then((_) => getData());
          return;
        }

        // set id_bazar ke sharedPreferences
        await prop.setString('id_bazar', data['data']['id_bazar'].toString());
        _idBazar = prop.getString('id_bazar');
      } while (_idBazar == '');

      // Proses get data bazar
      response = await get('${_env.baseURL}/bazar/$_idBazar', headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      }).timeout(Duration(seconds: 30));

      Map<String, dynamic> dataBazar = await jsonDecode(response.body);

      // Proses get data transaksi bazar
      response = await get('${_env.baseURL}/bazar/penjualan/$_idBazar',
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token'
          }).timeout(Duration(seconds: 30));

      Map<String, dynamic> dataTransaksi = await jsonDecode(response.body);
      List<dynamic> historyTransaksi = await dataTransaksi['data'];

      setState(() {
        _isLoading = false;
        _dataBazar = {
          'nama_bazar': dataBazar['data']['nama_bazar'].toString(),
          'tanggal_mulai': dataBazar['data']['tgl_mulai'].toString(),
          'tanggal_akhir': dataBazar['data']['tgl_akhir'].toString(),
        };
        _transaksiBazar = {
          'total_transaksi': '${dataTransaksi['recordsTotal']}',
          'data_transaksi': historyTransaksi,
        };
      });
    } on TimeoutException {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
        arguments:
            ErrorMessage(errorMessage: "Session expired.\nPlease re-login."),
      );
    } on SocketException catch (e) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
        arguments: ErrorMessage(errorMessage: e.toString()),
      );
    }
  }

  void showErrorMessage(String errorMsg) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Terjadi Kesalahan."),
            content: Text(errorMsg),
            actions: <Widget>[
              FlatButton(
                onPressed: () => getData(),
                child: Text("Ok"),
              )
            ],
          );
        });
  }
}
