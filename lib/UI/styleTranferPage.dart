import 'dart:typed_data';
import 'package:Editeur/GalleryParts/gallerySelector.dart';
import 'package:Editeur/UI/savingPage.dart';
import 'package:Editeur/UsefullWidget/filterIcon.dart';
import 'package:Editeur/imageUtilities.dart';
import 'package:Editeur/transfer.dart';
import 'package:Editeur/usefullWidget/previewImage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class StyleTransferPage extends StatefulWidget {
  final Uint8List imgBytes;
  final Widget previewImage;
  StyleTransferPage(this.imgBytes, this.previewImage);

  @override
  _StyleTransferPageState createState() => _StyleTransferPageState();
}

class _StyleTransferPageState extends State<StyleTransferPage> {
  final _filterRowHeight = 132.0;
  final sliderHeight = 40.0;
  final _appbarSize = 80.0;
  Uint8List _computedImage;
  Uint8List _computedImageScaled;
  Uint8List _preview;
  Uint8List _thumbnail;
  int _selectedStyle = -1;
  Transfer model = Transfer();
  bool loading = true;
  bool isPressed = false;
  final nbMaxOfStyle = 6;
  List<String> stylePaths = [];
  int _computedSliderValue;

  bool showSlider = false;
  int sliderValue = 80;

  //PictureSelection
  bool refresh = true;
  int selectedAlbumIndex = 0;
  bool willApply = false;
  List<AssetEntity> selectedAssets = [];
  AssetPathEntity selectedAlbum;

  AssetEntity savedImage;

  Future loadingModel;

  @override
  void initState() {
    super.initState();
    _selectedStyle = -1;
    this.loadStyles();
    loadingModel = this.loadModel();
    _preview = widget.imgBytes;
    _thumbnail = _preview;

    loading = false;
  }

  Future<void> loadModel() async {
    await model.loadModel();
    await model.loadOriginImageAsync(widget.imgBytes);
  }

  Future<void> onScaleUp() async {
    if (_computedImage != null) {
      await compute(noiseUpScaling, {
        "original": widget.imgBytes,
        "computed": _computedImage,
        "ratio": [this.sliderValue]
      }).then((List<int> img) async {
        _computedImageScaled = img as Uint8List;

        compute(computeThumbnailsByWidth, {
          "imgBytes": _computedImageScaled,
          "maxWidth": [1000]
        }).then((List<int> thumbnail) {
          setState(() {
            _preview = thumbnail as Uint8List;
            loading = false;
          });
        });
      });
    }
  }

  void onSave(context) {
    if (_computedImageScaled != null) Navigator.push(context, MaterialPageRoute(builder: (context) => SavingPage(_computedImageScaled)));
  }

  /*  Uint8List computeThumbnails(Uint8List imgBytes, {int maxWidth = 1080}) {
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
  } */

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
    for (int i = 0; i < nbMaxOfStyle; i++) {
      stylePaths.add("assets/styles/style$i.jpg");
    }
  }

  Future<void> applyStyle(int index) async {
    if (index != -1) {
      await model.loadStyleImage("assets/styles/style$index.jpg");
      await onTransfer();
    }
    return null;
  }

  Future<void> applyMultyStyle(List<Uint8List> assets) async {
    await model.loadStyleImages(assets);
    await onTransfer();
  }

  Future<void> onTransfer() async {
    await loadingModel;
    Uint8List ImageFiltered = await model.transferAsync();
    await onfilterApplied(ImageFiltered);
  }

  void onReapplyfilter() async {
    if (_selectedStyle != -1 && loading == false) {
      return this.onTapFilter(_selectedStyle);
    }
  }

  Future<void> onfilterApplied(Uint8List ImageFiltered) async {
    this._computedImage = ImageFiltered;
    this._computedSliderValue = this.sliderValue;
    this.selectedAssets = [];
    this.willApply = false;
    return await onScaleUp();
  }

  Widget modalBuild(BuildContext context, List<AssetPathEntity> albums) {
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
  }

  Future<void> summonModal(List<AssetPathEntity> albums) async {
    await showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return modalBuild(context, albums);
        }).then((value) async {
      if (this.selectedAssets.length > 0 && willApply && !refresh) {
        await Future.wait(this.selectedAssets.map((asset) => asset.thumbDataWithSize(256, 256)).toList()).then((List<Uint8List> assets) async {
          setState(() {
            loading = true;
            _selectedStyle = nbMaxOfStyle;
          });
          await applyMultyStyle(assets);
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
    if (_selectedStyle == index && index != nbMaxOfStyle && index != -1) {
      return setState(() {
        showSlider = !showSlider;
      });
    }
    if (index == nbMaxOfStyle) {
      if (_selectedStyle == index) {
        setState(() {
          showSlider = !showSlider;
        });
      }
      if (!showSlider) {
        await onSelectPicture();
      }
    } else {
      if (loading == false && (_selectedStyle != index || _selectedStyle == index && this.sliderValue != this._computedSliderValue)) {
        if (index == -1) {
          return setState(() {
            showSlider = false;
            _selectedStyle = index;
            _preview = _thumbnail;
          });
        }
        setState(() {
          showSlider = false;
          loading = true;
          _selectedStyle = index;
        });
        await applyStyle(index);
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
            onPressed: () => onSave(context),
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
              onLongPress: () {
                setState(() {
                  isPressed = true;
                });
              },
              child: Listener(
                  onPointerDown: (event) => {},
                  onPointerUp: (event) => {
                        setState(() {
                          isPressed = false;
                        })
                      },
                  child: PreviewImage(_preview, loading, isPressed, _thumbnail)),
            ),
          ),
          showSlider
              ? Container(
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
                            onPressed: () {
                              setState(() {
                                loading = true;
                              });
                              return onScaleUp();
                            },
                            icon: Icon(
                              sliderValue == _computedSliderValue ? Icons.photo_filter_outlined : Icons.photo_filter,
                            )),
                      ),
                    ],
                  ),
                )
              : Container(),

          //container of the filters
          Container(
              height: _filterRowHeight, //110
              child: Center(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: nbMaxOfStyle + 2,
                  separatorBuilder: (context, index) => Container(height: _filterRowHeight, width: 10),
                  itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                      child: (index == 0 || index == nbMaxOfStyle + 1)
                          ? Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: _selectedStyle == index - 1 ? Theme.of(context).colorScheme.secondary : Colors.black26),
                              ),
                              child: InkWell(
                                  onTap: () => onTapFilter(index - 1),
                                  child: index == 0
                                      ? widget.previewImage
                                      : /*index == nbMaxOfStyle + 1*/ Icon(
                                          Icons.image,
                                          size: 80,
                                        )))
                          : FilterIcon((_selectedStyle == index - 1), () => onTapFilter(index - 1), "assets/styles/style${index - 1}.jpg", "Text")),
                ),
              ))
        ],
      ),
    );
  }
}
