import 'dart:async';
import 'dart:typed_data';

import 'package:Editeur/EditionPage.dart';
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
    await PhotoManager.getAssetPathList().then((value) {
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
                Spacer(
                  flex: 1,
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

                Spacer(
                  flex: 1,
                ),
                InkWell(
                    child: Icon(Icons.mode_edit),
                    onTap: () => {this.selectedPictureData != null ? Navigator.push(context, MaterialPageRoute(builder: (context) => EditionPage(this.selectedPictureData))) : print("select an Image")}),
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

class DropDownAlbums extends StatelessWidget {
  final List<AssetPathEntity> albums;
  final Function onSelection;
  final int selectedAlbumIndex;

  const DropDownAlbums({Key key, @required this.albums, @required this.onSelection, @required this.selectedAlbumIndex}) : super(key: key);

  List<PopupMenuItem<int>> getMenuEntry(BuildContext context) {
    List<PopupMenuItem<int>> menuEntries = [];
    for (int i = 0; i < albums.length; i++) {
      menuEntries.add(PopupMenuItem<int>(
          value: i,
          child: Container(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(albums[i].name), Text("${albums[i].assetCount}")]),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5.0),
              color: Theme.of(context).colorScheme.surface,
            ),
          )));
    }
    return menuEntries;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      initialValue: selectedAlbumIndex,
      child: Container(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text(albums[selectedAlbumIndex].name),
              Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
        color: Theme.of(context).colorScheme.surface,
      ),
      onSelected: (int result) {
        onSelection(result);
      },
      itemBuilder: (BuildContext context) => getMenuEntry(context),
    );
  }
}

class AlbumViewer extends StatefulWidget {
  final AssetPathEntity album;
  final Function onSelect;
  AlbumViewer({Key key, @required this.album, this.onSelect}) : super(key: key);

  static final int crossCount = 4;
  static final int pagesize = crossCount * 10;
  static final int separatorSize = 10;
  static final int thumbnailSize = 150;

  @override
  State<AlbumViewer> createState() => _AlbumViewerState();
}

class _AlbumViewerState extends State<AlbumViewer> {
  List<Widget> _mediaList = [];
  int selectedIndex = -1;
  int currentPage = 0;
  int loadedImages = 0;

  int lastPage;

  @override
  void initState() {
    super.initState();
    _fetchNewMedia();
  }

  Future<List<Map<String, Object>>> getAssets(int page, int size) {
    int nbOfImage = widget.album.assetCount;
    int nbOfPage = (nbOfImage / AlbumViewer.pagesize).ceil();

    return widget.album.getAssetListPaged(/* (nbOfPage-1) - */ page, nbOfImage).then((List<AssetEntity> assets) {
      assets.removeWhere((AssetEntity element) => element.type != AssetType.image);
      assets = assets.reversed.toList();
      return Future.wait(assets.map((asset) async {
        return await asset.thumbDataWithSize(size, size).then((thumb) {
          Map<String, Object> img = {"thumb": thumb, "asset": asset};
          return img;
        });
      }).toList());
    });
  }

  void _handleScrollEvent(ScrollNotification scroll) {
    if (scroll.metrics.pixels / scroll.metrics.maxScrollExtent > 0.33) {
      if (currentPage != lastPage) {
        _fetchNewMedia();
      }
    }
  }

  _fetchNewMedia() async {
    lastPage = currentPage;
    var result = await PhotoManager.requestPermission();
    if (result) {
      // success
      //load the media list
      int nbOfImage = widget.album.assetCount;

      int nbOfPage = (nbOfImage / AlbumViewer.pagesize).ceil();
      if (currentPage < nbOfPage) {
        List<AssetEntity> media = await widget.album.getAssetListPaged((nbOfPage - 1) - currentPage, AlbumViewer.pagesize);
        
        media = media.reversed.toList();
        media.removeWhere((element) => element.type == AssetType.video);
        while (media.length < AlbumViewer.pagesize && currentPage+1 < nbOfPage) {
          currentPage++;
          List<AssetEntity> newMedia = await widget.album.getAssetListPaged((nbOfPage - 1) - currentPage, AlbumViewer.pagesize);
          newMedia = newMedia.reversed.toList();
          newMedia.removeWhere((element) => element.type == AssetType.video);
          media.addAll(newMedia);
        }
        print("media : ${media.length}");

        List<Widget> temp = [];
        int indexStart = _mediaList.length;

        for (int i = 0; i < media.length; i++) {
          temp.add(FutureBuilder(
            future: media[i].thumbDataWithSize(AlbumViewer.thumbnailSize, AlbumViewer.thumbnailSize),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return InkWell(
                  onTap: () => onSelect(i + indexStart, media[i]),
                  child: Container(
                    width: 100,
                    height: 100,
                    child: media[i].type == AssetType.video 
                    ? Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: EdgeInsets.only(right: 5, bottom: 5),
                          child: Text("${(media[i].duration/60).ceil()-1}:${media[i].duration%60}")
                        ))
                : Image.memory(
                      snapshot.data,
                      //cacheWidth: media[i].width < media[i].height ? 150 : ((media[i].height / media[i].width) * 150).round(),
                      //cacheHeight: media[i].width < media[i].height ? ((media[i].width / media[i].height)* 100).round() : 100,
                      fit: BoxFit.cover,
                  ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(5.0),
                      
                    ),
                  ),
                );
              } else {
                return Container();
              }
            },
          ));
        }

        _mediaList.addAll(temp);
        if (_mediaList.length > nbOfImage) {
          print("error");
        }

        setState(() {
          currentPage++;
        });
      }
    } else {
      // fail
      /// if result is fail, you can call `PhotoManager.openSetting();`  to open android/ios applicaton's setting to get permission
    }
  }

  void onSelect(int index, AssetEntity asset) {
    if (index == selectedIndex) {
      setState(() {
        selectedIndex = -1;
      });
    } else {
      setState(() {
        print(index);
        selectedIndex = index;
      });
    }
    widget.onSelect(asset);
    //widget.onSelect(_mediaList[index])
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 300,
          width: MediaQuery.of(context).size.width,
          child: selectedIndex == -1 ? Container(): _mediaList[selectedIndex]),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scroll) {
              _handleScrollEvent(scroll);
              return;
            },
            child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 125.0,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 0,
                  childAspectRatio: 1.0,
                ),
                itemCount: _mediaList.length,
                itemBuilder: (context, index) {
                  return Container(
                    height: 105,
                    width: 105,
                    child: _mediaList[index],
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(color: selectedIndex == index ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.background, width: 5),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  );
                }),
          ),
        ),
      ],
    );
  }
}
