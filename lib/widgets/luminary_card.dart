import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class LuminaryCard extends StatelessWidget {
  final Widget child;
  final Color? rightStripColor;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const LuminaryCard({
    super.key,
    required this.child,
    this.rightStripColor,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.cardBorder, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius - 1),
        child: rightStripColor != null
            ? Stack(
                children: [
                  Padding(
                    padding: padding ?? const EdgeInsets.all(0),
                    child: child,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: AppDimensions.colorStripWidth,
                      color: rightStripColor,
                    ),
                  ),
                ],
              )
            : Padding(
                padding: padding ?? const EdgeInsets.all(0),
                child: child,
              ),
      ),
    );

    if (onTap == null) return inner;

    return GestureDetector(
      onTap: onTap,
      child: inner,
    );
  }
}
