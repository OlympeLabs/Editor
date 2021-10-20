// @dart=2.9
import 'package:Editeur/UI/Home.dart';
import 'package:flutter/material.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final ColorScheme darkTheme = ColorScheme(
    background: Color(0xff001B2E),
    onBackground: Color(0xFFE0F1FD),
    primary: Color(0xff99E0FF),
    primaryVariant: Color(0xff005980),
    onPrimary: Color(0xff001B2E),
    secondary: Color(0xffFFEBFF),
    secondaryVariant: Color(0xffcc66cc),
    onSecondary: Color(0xff001B2E),
    error: Color(0xff750D37),
    onError: Color(0xffffffff),
    surface: Color(0xff003C66),
    onSurface: Color(0xffffffff),
    brightness: Brightness.dark,
  );
 
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "L'Editeur",
      theme: ThemeData.from(colorScheme: darkTheme),
      home: MyHomePage(),
    );
  }
}
