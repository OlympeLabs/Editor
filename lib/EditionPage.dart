import 'dart:typed_data';

import 'package:flutter/material.dart';

class EditionPage extends StatefulWidget {
  Uint8List imgBytes;
  EditionPage(this.imgBytes);

  @override
  _EditionPageState createState() => _EditionPageState();
}

class _EditionPageState extends State<EditionPage> {
  final _filterRowHeight= 50.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          //container of the imagePreview
          Container(
            height: MediaQuery.of(context).size.height - _filterRowHeight,
            color: Colors.grey,
          ),
          //container of the filters
          Container(
            height: _filterRowHeight,
            color: Colors.deepOrange,

          )
        ],
      ),
    );
  }
}
