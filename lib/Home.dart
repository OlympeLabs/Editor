
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final _picker  = ImagePicker();

  @override
  void initState() {
    super.initState();
  }




  Future<void> pick_image() async {
    PickedFile image = await _picker.getImage();
    Navigator.push(context, )
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FloatingActionButton(
              onPressed: (){print("hello word");},
              tooltip: 'Select a picture',
              child: Icon(Icons.image , color: Theme.of(context).buttonColor, size: 50),
            ), // This trailing comma makes auto-formatting nicer for build methods.
          ],
        ),
      ),
    );
  }
}
