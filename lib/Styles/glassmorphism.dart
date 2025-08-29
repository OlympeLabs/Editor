import 'dart:ui';
import 'package:flutter/material.dart';

class GlassMorphism extends StatelessWidget {
  const GlassMorphism({
    required this.child,
    required this.start,
    required this.end,
    required this.border,
    super.key,
  });

  final Widget child;
  final double start;
  final double end;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withAlpha((start * 255.0).toInt()),
                Colors.white.withAlpha((end * 255.0).toInt()),
              ],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            borderRadius: BorderRadius.all(Radius.circular(10)),
            border: Border.all(
              width: border ? 1.5 : 5,
              color: Colors.white.withAlpha((0.2 * 255.0).toInt()),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
