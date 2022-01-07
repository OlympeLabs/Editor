import 'package:flutter/material.dart';

class FilterIcon extends StatelessWidget {
  bool isSelected;
  Function onTap;
  String assetPath;
  String title;

  FilterIcon(this.isSelected, this.onTap, this.assetPath, this.title, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: 100,
      child: Column(
        children: [
          Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: this.isSelected ? Theme.of(context).colorScheme.secondary : Colors.black26),
              ),
              child: InkWell(
                  onTap: onTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        assetPath,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        cacheHeight: 126,
                        cacheWidth: 126,
                      ),
                    ],
                  ))),
          Container(
              height: 20,
              child: Text(
                title,
                style: TextStyle(fontWeight: this.isSelected ? FontWeight.bold : FontWeight.normal),
              ))
        ],
      ),
    );
  }
}
