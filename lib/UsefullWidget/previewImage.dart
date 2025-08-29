import 'dart:typed_data';
import 'package:Editeur/usefullWidget/load.dart';
import 'package:flutter/material.dart';

class PreviewImage extends StatelessWidget {
  PreviewImage({
    required this.preview,
    required this.loading,
    required this.isPressed,
    required this.original,
    super.key,
  });
  final Uint8List preview;
  final Uint8List original;
  final bool loading;
  final bool isPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: <Widget>[
          Center(
              child: Image.memory(
            !loading && isPressed
                ? original
                : preview, //_thumbnail != null ? _thumbnail : computeThumbnail(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height - (_appbarSize + _filterRowHeight + sliderHeight)),
            fit: BoxFit.contain,
          )),
          loading ? Center(child: Loading()) : Container(),
        ],
      ),
    );
  }
}
