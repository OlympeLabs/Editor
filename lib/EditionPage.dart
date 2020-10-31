import 'dart:typed_data';

import 'package:flutter/material.dart';

class EditionPage extends StatefulWidget {
  Uint8List imgBytes;
  EditionPage(this.imgBytes);

  @override
  _EditionPageState createState() => _EditionPageState();
}

class _EditionPageState extends State<EditionPage> {
  final _filterRowHeight= 100.0;
  final _appbarSize= 80.0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        title: Container(
          height: _appbarSize,
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          //container of the imagePreview
          Container(
            height: MediaQuery.of(context).size.height - (_appbarSize + _filterRowHeight),
            width: MediaQuery.of(context).size.width,
            child: Image.memory(widget.imgBytes, fit: BoxFit.contain,),
          ),
          //container of the filters
          Container(
            height: _filterRowHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 20,
              separatorBuilder: (context, index)=> Container(height: _filterRowHeight ,width: 50),
              itemBuilder: (context, index)=> Container(height: 90 , width: 90 ,color: Colors.yellow,),),

          )
        ],
      ),
    );
  }
}
