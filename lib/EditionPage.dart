import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:styletranspher/Transfer.dart';

class EditionPage extends StatefulWidget {
  Uint8List imgBytes;
  EditionPage(this.imgBytes);

  @override
  _EditionPageState createState() => _EditionPageState();
}

class _EditionPageState extends State<EditionPage> {
  final _filterRowHeight= 110.0;
  final _appbarSize= 80.0;
  Uint8List _preview;
  int _selectedStyle;
  Transfer model = Transfer();
  bool loading;
  final nb_style = 43;

  @override
  void initState() {
    _selectedStyle = -1;
    model.loadModel();
    _preview = widget.imgBytes;
    loading = false;
  }

  Future<void> applyStyle(int index, {Uint8List style}) async {
    if(style== null)
      style = await model.loadStyleImage("assets/styles/style${index}.jpg");
    model.transfer(widget.imgBytes,style ).then((filteredImg){
        _preview = filteredImg;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        title: Container(
          height: _appbarSize,
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          //container of the imagePreview
          Container(
            height: MediaQuery.of(context).size.height - (_appbarSize + _filterRowHeight),
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: Stack(
                children: [
                  Center(child:Image.memory(_preview, fit: BoxFit.contain,)),
                  loading ? Center(child:Container(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("loading ...", style: TextStyle(fontSize: 30),),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      color: Colors.white.withAlpha(150)
                    ),
                  )
                  ) : Container(),
                ],
              ),
            ),
          ),
          //container of the filters
          Container(
            height: _filterRowHeight,
            child: Center(
                child : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: nb_style+1,
                  separatorBuilder: (context, index)=> Container(height: _filterRowHeight ,width: 10),
                  itemBuilder: (context, index)=>
                    Padding(
                      padding: const EdgeInsets.only(top:5.0, bottom: 5.0),
                      child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                            color: _selectedStyle == index ? Colors.white : Colors.black26
                            ),
    ),
                          child: InkWell(
                            onTap: () async {
                              if (_selectedStyle != index && loading == false){
                                if(index <nb_style) {
                                  setState(() {
                                    loading = true;
                                    _selectedStyle = index;
                                  });
                                  Future.delayed(Duration(milliseconds: 5)).then((value) =>
                                    applyStyle(index).then((value) =>
                                      setState(() {
                                        loading = false;
                                      })));
                                }else{
                                  setState(() {
                                    loading = true;
                                    _selectedStyle = -1;
                                  });
                                  pick_image().then((styleImg) {
                                    if(styleImg != null){
                                      return applyStyle(index, style : styleImg).then((value) =>
                                        setState(() {
                                          loading = false;
                                        }));
                                   }
                                  });
                                }
                              }
                            },
                            child: index < nb_style ? Image.asset("assets/styles/style${index}.jpg", fit: BoxFit.contain,) : Icon(Icons.image),

                          ),

                        ),
                    ),
                    ),
            ),

            ),
        ],
      ),
    );
  }

  Future<Uint8List> pick_image() async {
    ImagePicker _picker  = ImagePicker();
    if (await Permission.storage.request().isGranted) {
      PickedFile image;
      print("trying to get image");
      _picker.getImage(source: ImageSource.gallery).then((image) async {
        if(image != null){
          String path = image.path;
          return model.loadStyleImage(path);
        }else{
          return null;
        }
      });
    }
  }
}


