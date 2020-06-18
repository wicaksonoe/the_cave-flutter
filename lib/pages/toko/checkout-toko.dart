import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thecave/env.dart';
import 'package:thecave/widget/loading.dart';

class DaftarBarangToko {
  const DaftarBarangToko({
    @required List<dynamic> listBarang,
  }) : listBarang = listBarang;

  final List<dynamic> listBarang;
}

class CheckoutToko extends StatefulWidget {
  @override
  _CheckoutTokoState createState() => _CheckoutTokoState();
}

class _CheckoutTokoState extends State<CheckoutToko> {
  final Env _env = Env();
  final _currencyFormater = NumberFormat.currency(
    symbol: 'Rp. ',
    decimalDigits: 0,
  );
  bool _isLoading = false;
  var _daftarTransaksi = List<dynamic>();
  int _totalBayar = 0;

  @override
  Widget build(BuildContext context) {
    final DaftarBarangToko _checkout =
        ModalRoute.of(context).settings.arguments;
    _totalBayar = 0;
    _daftarTransaksi.clear();

    for (var barang in _checkout.listBarang) {
      int jumlahBeli = barang['jumlah'];
      String convertHarga = barang['harga_jual']
          .toString()
          .replaceAll('Rp. ', '')
          .split(',')
          .join();
      int hargaTotal = int.parse(convertHarga) * jumlahBeli;

      _daftarTransaksi.add({
        'barcode': barang['barcode'],
        'nama': barang['nama'],
        'jumlah': barang['jumlah'],
        'harga': barang['harga_jual'],
        'hargaTotal': _currencyFormater.format(hargaTotal),
      });

      _totalBayar += hargaTotal;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Konfirmasi Pembayaran"),
      ),
      body: _isLoading
          ? CircleLoading()
          : Column(
              children: <Widget>[
                Expanded(
                  child: Scrollbar(
                    child: Container(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: ListView.builder(
                        itemCount: _daftarTransaksi.length,
                        itemBuilder: (context, index) {
                          var item = _daftarTransaksi[index];

                          return Container(
                            margin: EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(item['nama'].toString()),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text("Harga: ${item['harga']}"),
                                  Text("Jumlah Pembelian: ${item['jumlah']}"),
                                ],
                              ),
                              trailing: Text(item['hargaTotal']),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Card(
                    child: ListTile(
                      title: Text('Total Bayar'),
                      trailing: Text(_currencyFormater.format(_totalBayar)),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(20),
                  child: ButtonTheme(
                    minWidth: MediaQuery.of(context).size.width,
                    height: 60,
                    child: RaisedButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      color: Colors.green,
                      child: Text(
                        "Bayar",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        List<dynamic> barcode = List<dynamic>();
                        List<dynamic> jumlah = List<dynamic>(); 
 
                        for (var item in _daftarTransaksi) {
                          barcode.add(item['barcode']);
                          jumlah.add(item['jumlah']);
                        }

                        submitData(barcode, jumlah);
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> submitData(List barcode, List jumlah) async {
    setState(() => _isLoading = true);
    Response response;

    final prop = await SharedPreferences.getInstance();
    final token = prop.getString('token') ?? '';
    final url = "${_env.baseURL}/penjualan";

    try {
      response = await post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-type': 'application/json',
        },
        body: jsonEncode({
          'barcode': barcode,
          'jumlah': jumlah,
        }),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode != 200) {
        Flushbar(
          padding: EdgeInsets.fromLTRB(30, 25, 0, 25),
          message: "Error code: ${response.statusCode} | ${response.body}",
          duration: Duration(seconds: 3),
        )..show(context);
        setState(() => _isLoading = true);
        log("Error code: ${response.statusCode} | ${response.body}");
      } else {
        showSuccessDialog();
      }
    } on TimeoutException {
      setState(() => Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          ));
    }
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Sukses"),
          content: Text("Penjualan berhasil!"),
          actions: <Widget>[
            FlatButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/main-menu',
                (route) => false,
              ),
              child: Text("Close"),
            )
          ],
        );
      },
    );
  }
}
