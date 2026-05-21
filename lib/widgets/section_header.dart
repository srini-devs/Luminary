import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String text;
  final EdgeInsets? padding;

  const SectionHeader(this.text, {super.key, this.padding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(2, 12, 2, 4),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.sectionLabel,
      ),
    );
  }
}
