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
  bool _runInit = true;

  @override
  Widget build(BuildContext context) {
    if (_runInit) {
      final DaftarBarangToko _checkout =
          ModalRoute.of(context).settings.arguments;
      _daftarTransaksi.clear();

      for (var barang in _checkout.listBarang) {
        int hargaJual = formatHarga(barang['harga_jual']);
        int hargaGrosir = formatHarga(barang['harga_grosir']);
        int hargaPartai = formatHarga(barang['harga_partai']);

        _daftarTransaksi.add({
          'barcode': barang['barcode'],
          'nama': barang['nama'],
          'jumlah': barang['jumlah'],
          'harga_jual': hargaJual,
          'harga_grosir': hargaGrosir,
          'harga_partai': hargaPartai,
          'isPartai': false,
        });
      }

      _runInit = false;
    }

    _totalBayar = hitungKeranjang(_daftarTransaksi);

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
                                  Text(hargaBarang(item)),
                                  Text("Jumlah Pembelian: ${item['jumlah']}"),
                                  showPartaiButton(item)
                                      ? CheckboxListTile(
                                          title: Text("Harga partai"),
                                          value: item['isPartai'],
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          onChanged: (bool value) {
                                            // log(value.toString());
                                            setState(() {
                                              item['isPartai'] = value;
                                              // _totalBayar = hitungKeranjang(_daftarTransaksi);
                                            });
                                          },
                                        )
                                      : Container(),
                                ],
                              ),
                              trailing: Text(subTotalBarang(item)),
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
                        List<dynamic> isPartai = List<dynamic>();

                        for (var item in _daftarTransaksi) {
                          barcode.add(item['barcode']);
                          jumlah.add(item['jumlah']);

                          if (item['isPartai']) {
                            isPartai.add('1');
                          } else {
                            isPartai.add('0');
                          }
                        }

                        submitData(barcode, jumlah, isPartai);
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  int formatHarga(String harga) {
    String stringHarga =
        harga.toString().replaceAll('Rp. ', '').split(',').join();

    return int.parse(stringHarga);
  }

  int hitungKeranjang(List<dynamic> daftarBarang) {
    int totalHarga = 0;

    for (var barang in daftarBarang) {
      if (barang['jumlah'] > 99 && barang['isPartai'] == true) {
        totalHarga += barang['jumlah'] * barang['harga_partai'];
      } else if (barang['jumlah'] > 11) {
        totalHarga += barang['jumlah'] * barang['harga_grosir'];
      } else {
        totalHarga += barang['jumlah'] * barang['harga_jual'];
      }
    }

    return totalHarga;
  }

  String hargaBarang(Map<String, dynamic> barang) {
    if (barang['jumlah'] > 99 && barang['isPartai'] == true) {
      return "Harga: ${_currencyFormater.format(barang['harga_partai'])}";
    } else if (barang['jumlah'] > 11) {
      return "Harga: ${_currencyFormater.format(barang['harga_grosir'])}";
    } else {
      return "Harga: ${_currencyFormater.format(barang['harga_jual'])}";
    }
  }

  String subTotalBarang(Map<String, dynamic> barang) {
    int subTotal = 0;

    if (barang['jumlah'] > 99 && barang['isPartai'] == true) {
      subTotal = barang['jumlah'] * barang['harga_partai'];
    } else if (barang['jumlah'] > 11) {
      subTotal = barang['jumlah'] * barang['harga_grosir'];
    } else {
      subTotal = barang['jumlah'] * barang['harga_jual'];
    }

    return _currencyFormater.format(subTotal);
  }

  bool showPartaiButton(Map<String, dynamic> barang) => barang['jumlah'] > 99;

  Future<void> submitData(List barcode, List jumlah, List isPartai) async {
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
          'harga_partai': isPartai,
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
