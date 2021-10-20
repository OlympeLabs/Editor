import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'styleTranferPage.dart';
import 'selectionImagePage.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }
  
  


  Future<void> pickImage() async {
    //if (await Permission.storage.request().isGranted) {
      print("trying to get image");
      _picker.pickImage(source: ImageSource.gallery).then((image) async {
        if(image != null){
          return image.readAsBytes().then((value) => Navigator.push(context, MaterialPageRoute(builder: (context)=> StyleTransferPage(value))));
        }else{
          print("error image is null");
        }
      });
    /* }else{
      print("permission not granted");
    } */
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              height:  200,
              width:  200,
              child: FloatingActionButton(
                onPressed: ()=>Navigator.push(context, MaterialPageRoute(builder: (context)=> SelectionImagePage())),
                tooltip: 'Select a picture',
                child: Icon(Icons.image , color: Theme.of(context).cardColor , size: 100),
              ),
            ), // This trailing comma makes auto-formatting nicer for build methods.
          ],
        ),
      ),
    );
  }
}
