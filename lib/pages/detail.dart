import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thecave/env.dart';
import 'package:thecave/widget/loading.dart';
import 'login.dart';

class KodeTransaksi {
  KodeTransaksi({@required String kodeTrx}) : kodeTrx = kodeTrx;
  final String kodeTrx;
}

class DetailTransaksi extends StatefulWidget {
  @override
  _DetailTransaksiState createState() => _DetailTransaksiState();
}

class _DetailTransaksiState extends State<DetailTransaksi> {
  final _baseURL = Env().baseURL;
  final _currencyFormater =
      NumberFormat.currency(symbol: 'Rp. ', decimalDigits: 0);

  bool _isLoading = true;
  bool _returnBack = false;
  var _dataTransaksi = Map<String, dynamic>();
  String _token;
  String _idBazar;
  String _kodeTrx;
  List<Widget> _listBarang = List<Widget>();

  @override
  Widget build(BuildContext context) {
    final KodeTransaksi args = ModalRoute.of(context).settings.arguments;
    _kodeTrx = args.kodeTrx;

    if (_isLoading) {
      getDataTransaksi();
    }

    if (_returnBack) {
      Navigator.pop(context);
    }

//    print("TRX: $_dataTransaksi");
    return Scaffold(
      appBar: AppBar(title: Text("Detail Transaksi")),
      body: _isLoading ? CircleLoading() : tampilanNota(),
    );
  }

  Widget tampilanNota() {
    if (_dataTransaksi.length == 0) {
      return Text("DATA KOSONG");
    } else {
      return Scrollbar(
        child: ListView(children: _listBarang),
      );
    }
  }

  Widget detailNota() {
    return Container(
        padding: EdgeInsets.fromLTRB(30, 25, 30, 30),
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: {1: FractionColumnWidth(0.55)},
          children: <TableRow>[
            TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Text("Kode Transaksi"),
                ),
                Text(_dataTransaksi['kode_trx'].toString()),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Text("Nama Staff"),
                ),
                Text(_dataTransaksi['nama_pegawai'].toString()),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Text("Waktu Penjualan"),
                ),
                Text(_dataTransaksi['tanggal_penjualan'].toString()),
              ],
            ),
          ],
        ));
  }

  Future<void> getDataTransaksi() async {
    final prop = await SharedPreferences.getInstance();
    _token = prop.getString('token');
    _idBazar = prop.getString('id_bazar');

    try {
      Response response = await get(
        "$_baseURL/bazar/penjualan/$_idBazar/$_kodeTrx",
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      ).timeout(Duration(seconds: 30));

      switch (response.statusCode) {
        case 200:
          var data = await jsonDecode(response.body);
          if (data['success'] == true) {
            _dataTransaksi = await data['data'];
            generateList();
          } else {
            showErrorMessage(
              context,
              response.body,
              response.statusCode.toString(),
            );
          }
          setState(() => _isLoading = false);
          break;

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
          showErrorMessage(
            context,
            response.body,
            response.statusCode.toString(),
          );
          setState(() => _isLoading = false);
          break;
      }
    } on TimeoutException {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
        arguments:
            ErrorMessage(errorMessage: "Session expired.\nPlease re-login."),
      );
    }
  }

  Future showErrorMessage(
    BuildContext context,
    String errorMsg,
    String errorCode,
  ) async {
    showDialog(
      context: context,
      child: AlertDialog(
        title: Text("Terjadi Kesalahan.\nError Code: $errorCode"),
        content: Text(errorMsg),
        actions: <Widget>[
          FlatButton(
            onPressed: () {
              setState(() {
                _isLoading = false;
                _returnBack = true;
              });
              Navigator.pop(context);
            },
            child: Text("Ok"),
          )
        ],
      ),
    );
  }

  void generateList() {
    var totalBayar = 0;
    int hjual;
    int jumlah;
    int totalSatuan;

    _listBarang.add(
      Container(
        padding: EdgeInsets.fromLTRB(30, 25, 30, 40),
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: {1: FractionColumnWidth(0.55)},
          children: <TableRow>[
            TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Text("Kode Transaksi"),
                ),
                Text(_dataTransaksi['kode_trx'].toString()),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Text("Nama Staff"),
                ),
                Text(_dataTransaksi['nama_pegawai'].toString()),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Text("Waktu Penjualan"),
                ),
                Text(_dataTransaksi['tanggal_penjualan'].toString()),
              ],
            ),
          ],
        ),
      ),
    );

    for (var item in _dataTransaksi['barang']) {
      hjual = int.parse(item['hjual'].toString());
      jumlah = int.parse(item['jumlah'].toString());
      totalSatuan = jumlah * hjual;

      _listBarang.add(Container(
        padding: EdgeInsets.fromLTRB(15, 0, 20, 10),
        child: ListTile(
          title: Text(item['nama_barang'].toString()),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text("Jumlah pembelian: ${item['jumlah']}"),
              Text("Harga: ${_currencyFormater.format(hjual)}"),
            ],
          ),
          trailing:
              Text(_currencyFormater.format(totalSatuan)),
        ),
      ));

      totalBayar += totalSatuan;
    }

    _listBarang.add(
      Container(
        padding: EdgeInsets.fromLTRB(15, 30, 20, 20),
        child: ListTile(
          title: Text("Total bayar"),
          trailing: Text(_currencyFormater.format(totalBayar)),
        ),
      ),
    );
  }
}
