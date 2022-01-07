import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

///this is the dropdown menu that display all of the List<AssetPathEntity> [albums] given as parametter, and will execute [onSelection] when a new one is selected
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
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(albums[i].name),
                Text("${albums[i].assetCount}")
              ]),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(10.0),
        ),
      ),
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.0),
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
      onSelected: (int result) {
        onSelection(result);
      },
      itemBuilder: (BuildContext context) => getMenuEntry(context),
    );
  }
}

///this class display all of the picture contained in the AssetPathEntity [album] passed as argument and will execute the Function [onSelect] when a picture is selected
class AlbumViewer extends StatefulWidget {
  final AssetPathEntity album;
  final Function onSelect;

  AlbumViewer({Key key, @required this.album, this.onSelect}) : super(key: key);

  static final int crossCount = 4;
  static final int pagesize = crossCount * 10;
  static final int separatorSize = 10;
  static final int thumbnailSize = 150;
  static const SliverGridDelegate gridDelegate = const SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 125.0,
    mainAxisSpacing: 0,
    crossAxisSpacing: 0,
    childAspectRatio: 1.0,
  );

  @override
  State<AlbumViewer> createState() => _AlbumViewerState();
}

class _AlbumViewerState extends State<AlbumViewer> {
  List<Widget> _mediaList = [];

  Widget _selectedMedia = Container(
    height: 300,
    child: Center(
      child: Text("Select a picture"),
    ),
  );
  Uint8List _selectedMediaSource;
  int selectedIndex = -1;
  int currentPage = 0;
  int loadedImages = 0;

  int lastPage;

  @override
  void initState() {
    super.initState();
    _fetchNewMedia();
  }

  void _handleScrollEvent(ScrollNotification scroll) {
    if (scroll.metrics.pixels / scroll.metrics.maxScrollExtent > 0.33) {
      if (currentPage != lastPage) {
        _fetchNewMedia();
      }
    }
  }

  Uint8List ComputeThumbnails(Uint8List imgBytes, int size) {
    img.Image originalImage = img.decodeImage(imgBytes);
    return img.encodeJpg(img.copyResizeCropSquare(originalImage, size));
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
        while (media.length < AlbumViewer.pagesize && currentPage + 1 < nbOfPage) {
          currentPage++;
          List<AssetEntity> newMedia = await widget.album.getAssetListPaged((nbOfPage - 1) - currentPage, AlbumViewer.pagesize);
          newMedia = newMedia.reversed.toList();
          newMedia.removeWhere((element) => element.type == AssetType.video);
          media.addAll(newMedia);
        }

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
                        ? Align(alignment: Alignment.bottomLeft, child: Padding(padding: EdgeInsets.only(right: 5, bottom: 5), child: Text("${(media[i].duration / 60).ceil() - 1}:${media[i].duration % 60}")))
                        : Image.memory(
                            snapshot.data,
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
    if (index != selectedIndex) {
      setState(() {
        selectedIndex = index;
        _selectedMedia = FutureBuilder(
          future: asset.thumbDataWithSize(300, 300),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              _selectedMediaSource = snapshot.data;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 300,
                    width: 500,
                    decoration: BoxDecoration(
                      image: DecorationImage(image: MemoryImage(snapshot.data), fit: BoxFit.cover),
                    ),
                    child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(color: Theme.of(context).backgroundColor.withOpacity(0.5)),
                        )),
                  ),
                  Container(
                    height: 300,
                    child: Image.memory(
                      ComputeThumbnails(snapshot.data, 300),
                      cacheHeight: 300,
                      cacheWidth: 300,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              );

              /* Image.memory(
                      snapshot.data,
                      fit: BoxFit.contain,
                    ); */
            }
            return Container(
              height: 300,
            );
          },
          initialData: _selectedMediaSource != null ? _selectedMediaSource : null,
        );
      });
    }

    widget.onSelect(asset, _selectedMedia);
    //widget.onSelect(_mediaList[index])
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scroll) {
        _handleScrollEvent(scroll);
        return;
      },
      child: Column(
        children: [
          this._selectedMedia,
          Expanded(
              child: AssetGrid(_mediaList, [
            selectedIndex
          ])),
        ],
      ),
    );
  }
}

class AssetSelector extends StatefulWidget {
  final AssetPathEntity album;
  final Function onUpdateSelection;

  const AssetSelector({Key key, this.album, this.onUpdateSelection}) : super(key: key);

  @override
  State<AssetSelector> createState() => _AssetSelectorState();
}

class _AssetSelectorState extends State<AssetSelector> {
  List<Widget> _mediaList = [];
  List<int> selectedIndexes = [];
  Map<int, AssetEntity> selectedAssets = {};

  int currentPage = 0;
  int lastPage;

  @override
  void initState() {
    super.initState();
    _fetchNewMedia();
  }

  void onSelect(int index, AssetEntity asset) {
    if (selectedIndexes.contains(index)) {
      selectedIndexes.remove(index);
      selectedAssets[index] = null;
    } else {
      selectedIndexes.add(index);
      selectedAssets[index] = asset;
    }
    List<AssetEntity> selectedAsset = selectedAssets.values.toList();
    selectedAsset.removeWhere((element) => element == null);
    List<int> selectedIndex = selectedAssets.keys.toList();
    selectedIndex.removeWhere((element) => selectedAssets[element] == null);

    setState(() {
      widget.onUpdateSelection(selectedAsset);
    });
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
        while (media.length < AlbumViewer.pagesize && currentPage + 1 < nbOfPage) {
          currentPage++;
          List<AssetEntity> newMedia = await widget.album.getAssetListPaged((nbOfPage - 1) - currentPage, AlbumViewer.pagesize);
          newMedia = newMedia.reversed.toList();
          newMedia.removeWhere((element) => element.type == AssetType.video);
          media.addAll(newMedia);
        }

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
                    child: Image.memory(
                      snapshot.data,
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

  void _handleScrollEvent(ScrollNotification scroll) {
    if (scroll.metrics.pixels / scroll.metrics.maxScrollExtent > 0.33) {
      if (currentPage != lastPage) {
        _fetchNewMedia();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scroll) {
          _handleScrollEvent(scroll);
          return;
        },
        child: AssetGrid(_mediaList, selectedIndexes));
  }
}

class AssetGrid extends StatelessWidget {
  final List<Widget> _mediaList;
  final List<int> selectedIndexes;
  const AssetGrid(this._mediaList, this.selectedIndexes, {Key key}) : super(key: key);

  //the width of the border of the selected image
  static const double widthBorder = 2;
  static const double borderRadius = 20.0;

  @override
  Widget build(BuildContext context) {
    return _mediaList.length != 0
        ? GridView.builder(
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
                child: ClipRRect(borderRadius: BorderRadius.circular(borderRadius), child: _mediaList[index]),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: selectedIndexes.contains(index) ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.background, width: widthBorder),
                  borderRadius: BorderRadius.circular(borderRadius + widthBorder),
                ),
              );
            })
        : Center(
            child: Text("No picture in this album"),
          );
  }
}
