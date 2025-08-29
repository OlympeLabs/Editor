import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

class SavingPage extends StatefulWidget {
  SavingPage(
    this.imageToSave, {
    super.key,
  });
  final Uint8List imageToSave;

  @override
  State<SavingPage> createState() => _SavingPageState();
}

class _SavingPageState extends State<SavingPage> {
  String title = "image_${DateTime.now().millisecondsSinceEpoch}";
  AssetEntity? savedImageAsset = null;

  Future<AssetEntity?> savedImage({
    required String title,
  }) async {
    return await PhotoManager.editor.saveImage(
      this.widget.imageToSave,
      title: title,
      filename: "$title.jpg",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Save or Share",
          style: TextStyle(fontFamily: "Courgette"),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: (MediaQuery.of(context).size.height - 80) * 0.9,
            child: Center(
                child: Image.memory(
              widget.imageToSave,
              fit: BoxFit.contain,
            )),
          ),
          Container(
            height: (MediaQuery.of(context).size.height - 80) * 0.1,
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () async {
                    if (savedImageAsset == null)
                      savedImageAsset = await this.savedImage(title: title);
                    if (savedImageAsset != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "The image is saved to ${savedImageAsset?.relativePath ?? ""} ",
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                              ),
                            ],
                          ),
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                        ),
                      );
                    }
                  },
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        child: Icon(Icons.save),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Save"),
                      )
                    ],
                  ),
                ),
                InkWell(
                  onTap: () async {
                    savedImageAsset = await this.savedImage(title: title);
                    File? imageFile = await savedImageAsset?.loadFile();
                    if (imageFile != null) {
                      await SharePlus.instance.share(
                        ShareParams(
                            title:
                                "Regarde cette photo que j'ai retouché grace a l'application ${"L'Editeur"} #EditeurApp",
                            files: [
                              XFile.fromData(imageFile.readAsBytesSync(),
                                  name: title),
                            ]),
                      );
                    }
                  },
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        child: Icon(Icons.share),
                      ),
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
