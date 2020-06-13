import 'package:flutter/material.dart';

class CircleLoading extends StatelessWidget {
  const CircleLoading({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Center(
            child: CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }
}
