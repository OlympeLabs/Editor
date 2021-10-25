import 'dart:typed_data';
import 'package:Editeur/GalleryParts/gallerySelector.dart';
import 'package:Editeur/UI/savingPage.dart';
import 'package:Editeur/transfer.dart';
import 'package:Editeur/usefullWidget/previewImage.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image/image.dart' as img;

class StyleTransferPage extends StatefulWidget {
  final Uint8List imgBytes;
  final Widget previewImage;
  StyleTransferPage(this.imgBytes, this.previewImage);

  @override
  _StyleTransferPageState createState() => _StyleTransferPageState();
}

class _StyleTransferPageState extends State<StyleTransferPage> {
  final _filterRowHeight = 110.0;
  final sliderHeight = 40.0;
  final _appbarSize = 80.0;
  Uint8List _computedImage;
  Uint8List _preview;
  Uint8List _thumbnail;
  int _selectedStyle = -1;
  Transfer model = Transfer();
  bool loading = true;
  bool isPressed = false;
  final nbStyle = 6;
  List<String> stylePaths = [];
  int _computedSliderValue;
  int sliderValue = 80;

  //PictureSelection
  bool refresh = true;
  int selectedAlbumIndex = 0;
  bool willApply = false;
  List<AssetEntity> selectedAssets = [];
  AssetPathEntity selectedAlbum;


  AssetEntity savedImage;

  @override
  void initState() {
    super.initState();
    _selectedStyle = -1;
    this.loadStyles();
    model.loadModel().then((value) => model.loadOriginImage(widget.imgBytes));
    _preview = widget.imgBytes;//ComputeThumbnails(widget.imgBytes);
    _thumbnail = _preview;

    loading = false;
  }

  Uint8List ComputeThumbnails(Uint8List imgBytes, {int maxWidth = 1080}) {
    img.Image originalImage = img.decodeImage(imgBytes);
    int originalW = originalImage.width;
    int originalH = originalImage.height;
    double scaleW = originalW / maxWidth;

    if (scaleW > 1) {
      int w = maxWidth;
      int h = ((originalH / originalW) * maxWidth).round();
      return img.encodeJpg(img.copyResize(originalImage, width: w, height: h));
    }
    return imgBytes;
  }
  /*
  Uint8List computeThumbnail(double width, double height) {
    img.Image thumb = img.decodeImage(_preview);
    double ratioImg = thumb.width.roundToDouble() / thumb.height.roundToDouble();
    double ratioScreen = width.roundToDouble() / height.roundToDouble();
    int compW = thumb.width;
    int compH = thumb.height;
    if (ratioScreen < ratioImg) {
      //width too long
      compW = width.round();
      compH = (compW / thumb.width * compH).round();
    } else {
      //height too long
      compH = height.round();
      compW = (ratioImg * height).round();
    }

    var resultImage = img.copyResize(thumb, width: compW, height: compH, interpolation: img.Interpolation.cubic);
    var result = img.encodeJpg(resultImage);
    setState(() {
      _thumbnail = result;
    });
    return result;
  }*/

  IconData getIconFilter(int nbImage) {
    switch (nbImage) {
      case 0:
        return Icons.filter;
        break;
      case 1:
        return Icons.filter_1;
        break;
      case 2:
        return Icons.filter_2;
        break;
      case 3:
        return Icons.filter_3;
        break;
      case 4:
        return Icons.filter_4;
        break;
      case 5:
        return Icons.filter_5;
        break;
      case 6:
        return Icons.filter_6;
        break;
      case 7:
        return Icons.filter_7;
        break;
      case 8:
        return Icons.filter_8;
        break;
      case 9:
        return Icons.filter_9;
        break;
      default:
        return Icons.filter_9_plus;
    }
  }

  void loadStyles() {
    for (int i = 0; i < nbStyle; i++) {
      stylePaths.add("assets/styles/style$i.jpg");
    }
  }

  Future<Uint8List> applyStyle(int index) async {
    if (index != -1) {
      await model.loadStyleImage("assets/styles/style$index.jpg");
      return model.transfer(sliderValue);
    }
    return null;
  }

  Future<Uint8List> applyMultyStyle(List<Uint8List> assets) async {
    await model.loadStyleImages(assets);
    return model.transfer(sliderValue);
  }

  void onReapplyfilter() async {
    if (_selectedStyle != -1 && loading == false) {
      return this.onTapFilter(_selectedStyle);
    }
  }

  Future<void> summonModal(List<AssetPathEntity> albums) async {
    await showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (BuildContext context, StateSetter setmodalState) {
            return Column(
              children: <Widget>[
                Container(
                  color: Theme.of(context).backgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropDownAlbums(
                            albums: albums,
                            selectedAlbumIndex: this.selectedAlbumIndex,
                            onSelection: (int index) {
                              setmodalState(() {
                                this.selectedAssets = [];
                                this.selectedAlbumIndex = index;
                                this.selectedAlbum = albums[this.selectedAlbumIndex];
                                this.refresh = true;
                              });
                              willApply = false;
                              Navigator.pop(context);
                            }),
                        /* Container(
                            child: InkWell(
                              onTap: () {
                                setmodalState(() {
                                  multiSelection = !multiSelection;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Text("Multi Selection"),
                                    Container(
                                      width: 5,
                                    ),
                                    Icon(this.multiSelection ? Icons.one Icons.add_to_photos_outlined)
                                  ],
                                ),
                              ),
                            ),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: Theme.of(context).colorScheme.surface),
                          ), */
                        ElevatedButton(
                          onPressed: () {
                            willApply = true;
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Apply"),
                                Container(
                                  width: 5,
                                ),
                                Icon(getIconFilter(this.selectedAssets.length)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    child: AssetSelector(
                      album: selectedAlbum,
                      onUpdateSelection: (List<AssetEntity> selectedAssets) async {
                        setmodalState(() {
                          this.selectedAssets = selectedAssets;
                        });
                      },
                    ),
                  ),
                ),
              ],
            );
          });
        }).then((value) async {
      if (this.selectedAssets.length > 0 && willApply && !refresh) {
        await Future.wait(this.selectedAssets.map((asset) => asset.thumbDataWithSize(256, 256)).toList()).then((List<Uint8List> assets) {
          setState(() {
            loading = true;
            _selectedStyle = nbStyle;
          });
          Future.delayed(Duration(milliseconds: 500)).then((value) => applyMultyStyle(assets).then((value) => setState(() {
                loading = false;
                _computedImage = value;
                _computedSliderValue = this.sliderValue;
                _preview = ComputeThumbnails(value);
                this.selectedAssets = [];
                willApply = false;
              })));
        });
      } else {
        this.selectedAssets = [];
      }
    });
  }

  void onSelectPicture() async {
    await PhotoManager.getAssetPathList(type: RequestType.image).then((albums) async {
      albums.sort((AssetPathEntity a, AssetPathEntity b) => a.isAll ? -1 : a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      selectedAlbum = albums[this.selectedAlbumIndex];
      refresh = true;
      while (this.refresh) {
        refresh = false;
        await summonModal(albums);
      }
    });
  }

  void onTapFilter(index) async {
    if (index == nbStyle) {
      await onSelectPicture();
    } else {
      if (loading == false && (_selectedStyle != index || _selectedStyle == index && this.sliderValue != this._computedSliderValue)) {
        if (index == -1) {
          return setState(() {
            _selectedStyle = index;
            _preview = _thumbnail;
          });
        }
        setState(() {
          loading = true;
          _selectedStyle = index;
        });
        Future.delayed(Duration(milliseconds: 10)).then((value) => applyStyle(index).then((value) => setState(() {
              loading = false;
              _computedSliderValue = this.sliderValue;
              _computedImage = value;
              _preview = ComputeThumbnails(value);
            })));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        title: Container(
          height: _appbarSize,
        ),
        actions: [
          IconButton(
            onPressed: _computedImage != null
                ? ()=>Navigator.push(context, MaterialPageRoute(builder: (context) => SavingPage(_computedImage)))
                : null,
            icon: Icon(Icons.save),
          )
        ],
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          //container of the imagePreview
          Expanded(
            //height: MediaQuery.of(context).size.height - (_appbarSize + _filterRowHeight + sliderHeight), // appbar 80 row height 110
            //width: MediaQuery.of(context).size.width, //100%
            child: InkWell(
              onTap: null,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              onLongPress: (){
                setState(() {
                  isPressed = true;
                 });
              },
              child: Listener(
                  onPointerDown: (event) => {
                        
                      },
                  onPointerUp: (event) => {
                        setState(() {
                          isPressed = false;
                        })
                      },
                  child: PreviewImage(_preview, loading, isPressed, _thumbnail)),
            ),
          ),
          Container(
            height: sliderHeight, //20
            width: MediaQuery.of(context).size.width, //100%,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Slider(
                    value: sliderValue.roundToDouble(),
                    max: 100,
                    min: 0,
                    onChanged: (value) => {
                      setState(() {
                        sliderValue = value.round();
                      })
                    },
                    onChangeEnd: (value) => {
                      setState(() {
                        sliderValue = value.round();
                      })
                    },
                  ),
                ),
                Text("$sliderValue %"),
                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: IconButton(
                      onPressed: () => onReapplyfilter(),
                      icon: Icon(
                        sliderValue == _computedSliderValue ?  Icons.photo_filter_outlined : Icons.photo_filter,
                      )),
                ),
              ],
            ),
          ),

          //container of the filters
          Container(
            height: _filterRowHeight, //110
            child: Center(
              child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: nbStyle + 2,
                  separatorBuilder: (context, index) => Container(height: _filterRowHeight, width: 10),
                  itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                        child: Container(
                            height: 100,
                            width: 100,
                            //height 110 - ( 5 + 5)
                            decoration: BoxDecoration(
                              border: Border.all(color: _selectedStyle == index - 1 ? Theme.of(context).colorScheme.secondary : Colors.black26),
                            ),
                            child: InkWell(
                                onTap: () => onTapFilter(index - 1),
                                child: index == 0
                                    ? widget.previewImage
                                    : index == nbStyle + 1
                                        ? Icon(
                                            Icons.image,
                                            size: 80,
                                          )
                                        : Image.asset(
                                            "assets/styles/style${index - 1}.jpg",
                                            fit: BoxFit.cover,
                                            filterQuality: FilterQuality.high,
                                            cacheHeight: 126,
                                            cacheWidth: 126,
                                          ))),
                      )),
            ),
          ),
        ],
      ),
    );
  }
}


