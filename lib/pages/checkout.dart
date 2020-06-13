import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thecave/env.dart';
import 'package:thecave/widget/loading.dart';

import 'login.dart';

class DaftarBarang {
  final List<dynamic> listBarang;

  const DaftarBarang({
    @required List<dynamic> barang,
  }) : listBarang = barang;
}

class Checkout extends StatefulWidget {
  Checkout({Key key}) : super(key: key);

  @override
  _CheckoutState createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  final Env _env = Env();
  final _currencyFormater =
      NumberFormat.currency(symbol: 'Rp. ', decimalDigits: 0);

  bool _isLoading = false;
  var _daftarTransaksi = List<dynamic>();
  int _totalBayar = 0;

  @override
  Widget build(BuildContext context) {
    final DaftarBarang _checkout = ModalRoute.of(context).settings.arguments;
    _totalBayar = 0;
    _daftarTransaksi.clear();

    for (var barang in _checkout.listBarang) {
      int jumlahBeli = barang['jumlah'];
      String convertHarga = barang['harga_jual']
          .toString()
          .replaceAll("Rp. ", "")
          .split(",")
          .join();
      int hargaTotal = int.parse(convertHarga) * jumlahBeli;

      _daftarTransaksi.add({
        'barcode': barang['barcode'],
        'nama_barang': barang['nama_barang'],
        'jumlah': barang['jumlah'],
        'harga': barang['harga_jual'],
        'hargaTotal': _currencyFormater.format(hargaTotal),
      });

      _totalBayar += hargaTotal;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Konfirmasi pembayaran"),
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
                              title: Text(item['nama_barang'].toString()),
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
                      title: Text("Total Bayar"),
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
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      color: Colors.green,
                      child: Text(
                        'Bayar',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        var barcode = List<dynamic>();
                        var jumlah = List<dynamic>();

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

  Future<void> submitData(barcode, jumlah) async {
    setState(() => _isLoading = true);
    Response response;
    final prop = await SharedPreferences.getInstance();

    final token = prop.getString('token') ?? '';
    final idBazar = prop.getString('id_bazar') ?? '';
    final url = "${_env.baseURL}/bazar/penjualan/$idBazar";
    final body = jsonEncode({
      'barcode': barcode,
      'jumlah': jumlah,
    });

    try {
      response = await post(
        url,
        headers: {
          'Accept': 'aplication/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(Duration(seconds: 30));

      if (response.statusCode != 200) {
        print("Error code: ${response.statusCode} | ${response.body}");
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
          arguments:
              ErrorMessage(errorMessage: "Session expired.\nPlease re-login."),
        );
      } else {
        showSuccessDialog();
      }
    } on TimeoutException {
      setState(() {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      });
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
                    context, '/dashboard', (route) => false),
                child: Text("Close"),
              )
            ],
          );
        });
  }
}
