import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 8.0,
  });

  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: height,
          width: width ?? double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      );
}
