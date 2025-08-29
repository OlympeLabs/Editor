import 'package:flutter/material.dart';

class FilterIcon extends StatelessWidget {
  const FilterIcon({
    required this.isSelected,
    required this.assetPath,
    required this.title,
    this.onTap,
    super.key,
  });

  final bool isSelected;
  final String assetPath;
  final String title;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: 100,
      child: Column(
        children: <Widget>[
          Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(
                  color: this.isSelected
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.black26),
            ),
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    cacheHeight: 126,
                    cacheWidth: 126,
                  ),
                ],
              ),
            ),
          ),
          Container(
              height: 20,
              child: Text(
                title,
                style: TextStyle(
                    fontWeight:
                        this.isSelected ? FontWeight.bold : FontWeight.normal),
              ))
        ],
      ),
    );
  }
}
