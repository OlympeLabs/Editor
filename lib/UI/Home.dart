import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:Editeur/UI/selectionImagePage.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 200,
              width: 200,
              child: FloatingActionButton(
                onPressed: () async {
                  PermissionState result =
                      await PhotoManager.requestPermissionExtend();
                  if (result.isAuth) {
                    await Navigator.push(
                        context,
                        MaterialPageRoute<dynamic>(
                            builder: (BuildContext context) =>
                                SelectionImagePage()));
                  } else {
                    // fail
                    /// if result is fail, you can call `PhotoManager.openSetting();`  to open android/ios applicaton's setting to get permission
                    return PhotoManager.openSetting();
                  }
                },
                tooltip: 'Select a picture',
                child: Icon(Icons.image,
                    color: Theme.of(context).cardColor, size: 100),
              ),
            ), // This trailing comma makes auto-formatting nicer for build methods.
          ],
        ),
      ),
    );
  }
}
