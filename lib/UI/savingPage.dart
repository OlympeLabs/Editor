import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';


class SavingPage extends StatelessWidget {
  final Uint8List imageToSave;
  const SavingPage(this.imageToSave, {Key key}) : super(key: key);

  void save(context) async {
    AssetEntity savedImage = await PhotoManager.editor.saveImage(this.imageToSave);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "The image is saved to ${savedImage.relativePath} ",
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
    ));
  }

  void share(){

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Save or Share", style: TextStyle(fontFamily: "Courgette"),),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: (MediaQuery.of(context).size.height - 80) *0.9,
            child: Center(
              child: Image.memory(imageToSave, fit: BoxFit.contain,)
            ),
          ),
          Container(
            height: (MediaQuery.of(context).size.height -80)* 0.1,
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment : CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: (){ this.save(context);},
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(child: Icon(Icons.save),),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Save"),
                      )
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    this.share();
                  },
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(child: Icon(Icons.share),),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Share"),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
