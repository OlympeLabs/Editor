import 'dart:async';
import 'dart:typed_data';

import 'package:Editeur/GalleryParts/gallerySelector.dart';
import 'package:Editeur/UI/styleTranferPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class SelectionImagePage extends StatefulWidget {
  const SelectionImagePage({Key key}) : super(key: key);

  @override
  State<SelectionImagePage> createState() => _SelectionImagePageState();
}

class _SelectionImagePageState extends State<SelectionImagePage> {
  FutureOr<List<AssetPathEntity>> albums;
  int selectedAlbumIndex = 0;
  Uint8List selectedPictureData;

  final double appBarSize = 50.0;

  ScrollController myScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    getAlbums();
  }

  void getAlbums() async {
    await PhotoManager.getAssetPathList(type: RequestType.image).then((value) {
      value.sort((AssetPathEntity a, AssetPathEntity b) => a.isAll ? -1 : a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      setState(() {
        albums = value;
      });
    });
  }

  void onSelectAlbum(int index) {
    print("albumSelection : $index");
    setState(() {
      selectedAlbumIndex = index;
    });
  }

  Future<void> onSelectPhoto(AssetEntity selectedAsset) async {
    await selectedAsset.originBytes.then((Uint8List image) {
      selectedPictureData = image;
      //return Navigator.push(context, MaterialPageRoute(builder: (context) => EditionPage(image)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.value(albums),
        builder: (context, snapshot) {
          return Scaffold(
            appBar: AppBar(
  
              actions: [
                AspectRatio(
                  aspectRatio: 1,
                  child: IconButton(
                    splashRadius: 35,
                      icon:  Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                  ),
                ),
                //InkWell(child: Icon(Icons.arrow_back), onTap: () => Navigator.pop(context),),
                Container(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: snapshot.connectionState == ConnectionState.done
                        ? DropDownAlbums(
                            albums: snapshot.data as List<AssetPathEntity>,
                            selectedAlbumIndex: selectedAlbumIndex,
                            onSelection: onSelectAlbum,
                          )
                        : Container(),
                  ),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(25.0)),
                ),

                Expanded(
                  child: Container(),
                ),
                AspectRatio(
                  aspectRatio: 1,
                  child: IconButton(
                    splashRadius: 35,
                    icon:  Icon(Icons.mode_edit),
                    onPressed: () => {this.selectedPictureData != null ? Navigator.push(context, MaterialPageRoute(builder: (context) => StyleTransferPage(this.selectedPictureData))) : print("select an Image")}),
                ),
              ],
            ),
            body: snapshot.connectionState == ConnectionState.done ? AlbumViewer(album: (snapshot.data as List<AssetPathEntity>)[selectedAlbumIndex], onSelect: onSelectPhoto) : Container()
            /* Column(
              children: [
                
                
              ],
            ), */
          );
        });
  }
}