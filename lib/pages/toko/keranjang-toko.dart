import 'dart:convert';
import 'dart:developer';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thecave/env.dart';
import 'package:thecave/pages/login.dart';
import 'package:thecave/pages/toko/checkout-toko.dart';
import 'package:thecave/widget/loading.dart';

class KeranjangToko extends StatefulWidget {
  @override
  _KeranjangTokoState createState() => _KeranjangTokoState();
}

class _KeranjangTokoState extends State<KeranjangToko> {
  final Env _env = Env();
  var _listBarang = List<dynamic>();
  var _jumlahController = Map<String, dynamic>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Keranjang Toko"),
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
                Navigator.pushNamed(context, '/profile')
                    .then((_) => Navigator.pop(context));
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? CircleLoading()
          : Column(
              children: <Widget>[
                Expanded(
                  child: Scrollbar(
                    child: ListView.builder(
                      itemCount: _listBarang.length,
                      itemBuilder: (context, index) {
                        var item = _listBarang[index];

                        return Container(
                          margin: EdgeInsets.only(bottom: 30),
                          child: Dismissible(
                            key: Key(item['barcode']),
                            background: BackgroundDismissible(
                              padding: EdgeInsets.only(left: 30),
                              alignment: AlignmentDirectional.centerStart,
                              innerText: "Delete",
                            ),
                            secondaryBackground: BackgroundDismissible(
                              padding: EdgeInsets.only(right: 30),
                              alignment: AlignmentDirectional.centerEnd,
                              innerText: "Delete",
                            ),
                            child: Container(
                              padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey),
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  item['nama'].toString(),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Container(
                                  padding: EdgeInsets.only(top: 10, bottom: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: <Widget>[
                                          Padding(
                                            padding: EdgeInsets.only(right: 10),
                                            child:
                                                Text("Stock: ${item['stock']}"),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(left: 10),
                                            child: Text("Harga: "),
                                          ),
                                          Text(
                                            item['harga_jual'].toString(),
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          )
                                        ],
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(top: 20),
                                        child: Container(
                                          width: 120,
                                          child: TextField(
                                            autofocus: item['getFocus'],
                                            keyboardType: TextInputType.number,
                                            inputFormatters: <
                                                TextInputFormatter>[
                                              WhitelistingTextInputFormatter
                                                  .digitsOnly
                                            ],
                                            // controller: null,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(),
                                              errorText: item['hasError']
                                                  ? 'Stock kurang'
                                                  : null,
                                              labelText: "Jumlah beli",
                                            ),
                                            onChanged: (value) {
                                              int valInput =
                                                  int.parse(value.toString());
                                              int valStock = int.parse(
                                                  item['stock'].toString());
                                              if (valInput > valStock) {
                                                item['hasError'] = true;
                                              } else {
                                                item['hasError'] = false;
                                                _listBarang[index]['jumlah'] =
                                                    valInput;
                                              }

                                              setState(() {});
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            onDismissed: (direction) {
                              setState(() => _listBarang.removeAt(index));
                              Flushbar(
                                padding: EdgeInsets.fromLTRB(30, 25, 0, 25),
                                message: "Barang berhasil dihapus.",
                                duration: Duration(seconds: 3),
                              )..show(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(20),
                  child: CheckoutButton(
                    listBarang: _listBarang,
                  ),
                )
              ],
            ),
      floatingActionButton: Visibility(
        visible: !_isLoading,
        child: Container(
          margin: EdgeInsets.only(bottom: 100, right: 10),
          child: FloatingActionButton(
            child: Icon(
              Icons.add,
              color: Colors.white,
            ),
            onPressed: () => scanBarcode(),
          ),
        ),
      ),
    );
  }

  Future scanBarcode() async {
    try {
      String barcode = await BarcodeScanner.scan();
      // log(barcode);
      checkBarcode(barcode);
    } on PlatformException catch (e) {
      Flushbar(
        padding: EdgeInsets.fromLTRB(30, 25, 0, 25),
        message: e.toString(),
        duration: Duration(seconds: 3),
      )..show(context);
    } on FormatException catch (e) {
      Flushbar(
        padding: EdgeInsets.fromLTRB(30, 25, 0, 25),
        message: e.toString(),
        duration: Duration(seconds: 3),
      )..show(context);
    }
  }

  void checkBarcode(String barcode) async {
    setState(() => _isLoading = true);

    final prop = await SharedPreferences.getInstance();
    final token = prop.getString('token') ?? '';

    if (token == '') {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } else {
      // TODO: make request API to get barang data

      final String url = '${_env.baseURL}/barang/$barcode';

      Response response = await get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 401 || response.statusCode == 500) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
          arguments: ErrorMessage(
            errorMessage: "Session expired.\nPlease re-login.",
          ),
        );
      } else {
        // TODO: olah data response
        Map<String, dynamic> result = jsonDecode(response.body);

        if (result['success'] == true) {
          var cekDaftarBarang = _listBarang.where(
            (element) => element['barcode'] == barcode,
          );

          if (cekDaftarBarang.length == 0) {
            // TODO: push data barang ke list barang
            _listBarang.add({
              'barcode': barcode,
              'nama': result['data']['namabrg'].toString(),
              'jumlah': 0,
              'stock': result['data']['jumlah'],
              'harga_jual': result['data']['hjual'],
              'harga_grosir': result['data']['grosir'],
              'harga_partai': result['data']['partai'],
              'hasError': false,
              'getFocus': false,
            });

            for (var barang in _listBarang) {
              if (barang['jumlah'] > 0) {
                _jumlahController[barcode] =
                    TextEditingController(text: "${barang['jumlah']}");
              } else {
                _jumlahController[barcode] = TextEditingController();
              }
              barang['getFocus'] = false;
            }

            setState(() {
              _listBarang.last['getFocus'] = true;
              _isLoading = false;
            });
          } else {
            setState(() {
              _isLoading = false;
              Flushbar(
                padding: EdgeInsets.fromLTRB(30, 25, 0, 25),
                message: "Barang sudah masuk keranjang",
                duration: Duration(seconds: 3),
              )..show(context);
            });
          }
        } else {
          setState(() {
            _isLoading = false;
            Flushbar(
              padding: EdgeInsets.fromLTRB(30, 25, 0, 25),
              message: result['message'].toString(),
              duration: Duration(seconds: 3),
            )..show(context);
          });
        }

        log(response.body);
      }
    }
  }
}

class CheckoutButton extends StatelessWidget {
  const CheckoutButton({
    Key key,
    @required this.listBarang,
  }) : super(key: key);

  final List<dynamic> listBarang;

  @override
  Widget build(BuildContext context) {
    return isListValid()
        ? ButtonTheme(
            minWidth: MediaQuery.of(context).size.width,
            height: 60,
            child: RaisedButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              color: Colors.green,
              child: Text(
                "Hitung Pembayaran",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                // TODO: Navigate to checkout
                Navigator.of(context).pushReplacementNamed(
                  '/checkout-toko',
                  arguments: DaftarBarangToko(listBarang: listBarang),
                );
                log('NAVIGATE NOW');
              },
            ),
          )
        : ButtonTheme(
            minWidth: MediaQuery.of(context).size.width,
            height: 60,
            child: RaisedButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              color: Colors.grey,
              child: Text(
                "Hitung Pembayaran",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {},
            ),
          );
  }

  bool isListValid() {
    var errorList = listBarang.where((list) => list["hasError"] == true);
    var unaceptedValue = listBarang.where((list) => list["jumlah"] == 0);

    if (listBarang.length > 0 &&
        errorList.length == 0 &&
        unaceptedValue.length == 0) {
      return true;
    } else {
      return false;
    }
  }
}

class BackgroundDismissible extends StatelessWidget {
  const BackgroundDismissible({
    Key key,
    @required this.innerText,
    @required this.alignment,
    @required this.padding,
  }) : super(key: key);

  final String innerText;
  final AlignmentDirectional alignment;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding, //EdgeInsets.only(left: 30),
      alignment: alignment, //AlignmentDirectional.centerStart,
      color: Colors.red,
      child: Text(
        innerText,
        style: TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
