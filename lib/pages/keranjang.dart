import 'dart:convert';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thecave/env.dart';
import 'package:http/http.dart';
import 'package:thecave/pages/checkout.dart';
import 'package:thecave/widget/loading.dart';
import 'package:thecave/pages/login.dart';

class Keranjang extends StatefulWidget {
  Keranjang({Key key}) : super(key: key);

  @override
  _KeranjangState createState() => _KeranjangState();
}

class _KeranjangState extends State<Keranjang> {
  final Env _env = Env();

  String _errorMsg = "";
  var _listBarang = List<dynamic>();
  var _jumlahController = Map<String, dynamic>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Keranjang Belanja"),
      ),
      body: _isLoading
          ? CircleLoading()
          : Container(
              // padding: EdgeInsets.only(left: 20, right: 20),
              child: Column(
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
                              background: backgroundDismissible(),
                              secondaryBackground:
                                  secondaryBackgroundDismissible(),
                              child: itemCard(item, index),
                              onDismissed: (direction) {
                                setState(() {
                                  _listBarang.removeAt(index);
                                });
                                Scaffold.of(context).showSnackBar(SnackBar(
                                  content: Text("Berhasil menghapus barang."),
                                ));
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  CheckoutButton(listBarang: _listBarang),
                ],
              ),
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

  Container itemCard(item, int index) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey),
        ),
      ),
      child: ListTile(
        title: Text(
          item['nama_barang'].toString(),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Container(
          padding: EdgeInsets.only(top: 10, bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Text("Stock: ${item['stock']}"),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text("Harga: "),
                  ),
                  Text(
                    "${item['harga_jual']}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  width: 120,
                  child: TextField(
                    autofocus: item['getFocus'],
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      WhitelistingTextInputFormatter.digitsOnly
                    ],
                    controller: _jumlahController["${item['barcode']}"],
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      errorText: item['hasError'] ? "Stock kurang" : null,
                      labelText: "Jumlah beli",
                    ),
                    onChanged: (value) {
                      if (int.parse(value.toString()) >
                          int.parse(item['stock'].toString())) {
                        item['hasError'] = true;
                      } else {
                        item['hasError'] = false;
                        _listBarang[index]['jumlah'] = int.parse(value);
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
    );
  }

  Container secondaryBackgroundDismissible() {
    return Container(
      padding: EdgeInsets.only(right: 30),
      alignment: AlignmentDirectional.centerEnd,
      color: Colors.red,
      child: Text(
        "Delete",
        style: TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Container backgroundDismissible() {
    return Container(
      padding: EdgeInsets.only(left: 30),
      alignment: AlignmentDirectional.centerStart,
      color: Colors.red,
      child: Text(
        "Delete",
        style: TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future scanBarcode() async {
    try {
      String barcode = await BarcodeScanner.scan();
      checkBarcode(barcode);
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        setState(() => _errorMsg =
            "Tidak dapat mengakses kamera.\nMohon cek perijinan aplikasi.");
        showErrorDialog();
      } else {
        setState(() => _errorMsg = "Unknown error: $e");
        showErrorDialog();
      }
    } on FormatException {} catch (e) {
      setState(() => _errorMsg = "Unknown error: $e");
      showErrorDialog();
    }
  }

  void checkBarcode(String barcode) async {
    // TODO: melakukan pengecekan barcode, kalau tidak ada munculkan widget Dialog
    setState(() => _isLoading = true);

    final prop = await SharedPreferences.getInstance();
    final token = prop.getString('token') ?? '';
    final idBazar = prop.getString('id_bazar') ?? '';

    // Kalau token nya kosong, logout dan pindah ke halaman login
    if (token == '' || idBazar == '') {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } else {
      // buat request untuk meminta data barang berdasarkan barcode
      Response response = await get(
        '${_env.baseURL}/bazar/barang/$idBazar/$barcode',
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
          arguments:
              ErrorMessage(errorMessage: "Session expired.\nPlease re-login."),
        );
      }

      Map<String, dynamic> data = jsonDecode(response.body);

      if (data['success'] == true) {
        var cekDaftarBarang =
            _listBarang.where((list) => list["barcode"] == barcode);

        if (cekDaftarBarang.length > 0) {
          setState(() {
            _errorMsg = "Barang sudah ditambahkan sebelumnya.";
            _isLoading = false;
            showErrorDialog();
          });
        } else {
          setState(() {
            _listBarang.add({
              'barcode': barcode,
              'nama_barang': data['data']['nama_barang'].toString(),
              'jumlah': 0,
              'stock': data['data']['jumlah'],
              'harga_jual': data['data']['hjual'],
              'hasError': false,
              'getFocus': false,
            });

            for (var barang in _listBarang) {
              if (barang['jumlah'] > 0) {
                _jumlahController["${barang['barcode']}"] =
                    TextEditingController(text: "${barang['jumlah']}");
              } else {
                _jumlahController["${barang['barcode']}"] =
                    TextEditingController();
              }
              barang['getFocus'] = false;
            }

            _listBarang.last['getFocus'] = true;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMsg = "Data yang anda cari tidak dapat ditemukan.";
          _isLoading = false;
          showErrorDialog();
        });
      }
    }
  }

  void showErrorDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Terjadi Kesalahan"),
            content: Text(_errorMsg),
            actions: <Widget>[
              FlatButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("Close"),
              )
            ],
          );
        });
  }
}

class CheckoutButton extends StatelessWidget {
  const CheckoutButton({
    Key key,
    @required List<dynamic> listBarang,
  })  : _listBarang = listBarang,
        super(key: key);

  final List<dynamic> _listBarang;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: isValueAccepted()
          ? ButtonTheme(
              minWidth: MediaQuery.of(context).size.width,
              height: 60,
              child: RaisedButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                color: Colors.green,
                child: Text(
                  'Hitung Pembayaran',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/checkout',
                      arguments: DaftarBarang(barang: _listBarang));
                },
              ),
            )
          : ButtonTheme(
              minWidth: MediaQuery.of(context).size.width,
              height: 60,
              child: RaisedButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                color: Colors.grey[300],
                child: Text(
                  'Hitung Pembayaran',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () {},
              ),
            ),
    );
  }

  bool isValueAccepted() {
    var errorList = _listBarang.where((list) => list["hasError"] == true);
    var unaceptedValue = _listBarang.where((list) => list["jumlah"] == 0);

    if (_listBarang.length > 0 && errorList.length == 0 && unaceptedValue.length == 0) {
      return true;
    } else {
      return false;
    }
  }
}
