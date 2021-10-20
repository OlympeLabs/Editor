import 'dart:ui';

import 'package:flutter/material.dart';

class Loading extends StatelessWidget {
  const Loading({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: 300,
      child: Center(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          "Loading",
          style: TextStyle(fontSize: 30),
        ),
      )),
      decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(10)), color: Theme.of(context).colorScheme.surface)
    );
  }
}
