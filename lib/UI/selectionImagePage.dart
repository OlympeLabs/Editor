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
  Widget selectedPicturePreview;

  final double appBarSize = 50.0;

  ScrollController myScrollController = ScrollController();

  Future<PermissionState> allowed;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<bool> init() {
    allowed = getPerm();
    return Future.value(allowed).then((result) {
      if (result.isAuth) {
        getAlbums();
      }
      return result.isAuth;
    });
  }

  Future<PermissionState> getPerm() async {
    return await PhotoManager.requestPermissionExtend();
  }

  void getAlbums() async {
    PhotoManager.getAssetPathList(type: RequestType.image).then((value) {
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

  Future<void> onSelectPhoto(AssetEntity selectedAsset, Widget previewImage) async {
    selectedPicturePreview = previewImage;
    await selectedAsset.originBytes.then((Uint8List image) {
      selectedPictureData = image;
      //return Navigator.push(context, MaterialPageRoute(builder: (context) => EditionPage(image)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.value(allowed).then((result) async => await Future.value(albums)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
            return Scaffold(
              appBar: AppBar(
                actions: [
                  Container(
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropDownAlbums(
                          albums: snapshot.data as List<AssetPathEntity>,
                          selectedAlbumIndex: selectedAlbumIndex,
                          onSelection: onSelectAlbum,
                        )),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(25.0)),
                  ),
                  Expanded(
                    child: Container(),
                  ),
                  AspectRatio(
                    aspectRatio: 1,
                    child: IconButton(
                        splashRadius: 35,
                        icon: Icon(Icons.mode_edit),
                        onPressed: () => {
                              this.selectedPictureData != null ? Navigator.push(context, MaterialPageRoute(builder: (context) => StyleTransferPage(this.selectedPictureData, this.selectedPicturePreview))) : print("select an Image")
                            }),
                  ),
                ],
              ),
              body: AlbumViewer(album: (snapshot.data as List<AssetPathEntity>)[selectedAlbumIndex], onSelect: onSelectPhoto),
              /* Column(
              children: [
                
                
              ],
            ), */
            );
          } else {
            return Scaffold(
              body: Container(
                width: MediaQuery.of(context).size.width * 4 / 5,
                child: Center(
                  child: FutureBuilder(
                      future: Future.value(allowed),
                      builder: (context, permSnapshot) {
                        if (permSnapshot.connectionState == ConnectionState.done && !(permSnapshot.data as PermissionState).isAuth) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("The application need access to your gallery to display your photos"),
                              TextButton(
                                onPressed: () async {
                                  bool isAlowed = await init();
                                  if (!isAlowed) PhotoManager.openSetting();
                                },
                                child: Text("Continue"),
                              ),
                            ],
                          );
                        } else {
                          return CircularProgressIndicator();
                        }
                      }),
                ),
              ),
            );
          }
        });
  }
}
