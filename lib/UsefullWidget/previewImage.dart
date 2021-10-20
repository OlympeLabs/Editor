import 'dart:typed_data';
import 'package:Editeur/usefullWidget/load.dart';
import 'package:flutter/material.dart';

class PreviewImage extends StatelessWidget {
  final Uint8List _preview;
  final Uint8List original;
  final bool loading;
  final bool isPressed;

  PreviewImage(this._preview, this.loading, this.isPressed, this.original, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Center(
              child: Image.memory(
            !loading && isPressed
                ? original
                : _preview, //_thumbnail != null ? _thumbnail : computeThumbnail(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height - (_appbarSize + _filterRowHeight + sliderHeight)),
            fit: BoxFit.contain,
          )),
          loading ? Center(child: Loading()) : Container(),
        ],
      ),
    );
  }
}
