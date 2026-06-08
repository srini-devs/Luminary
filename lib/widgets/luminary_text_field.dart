import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import 'section_header.dart';

class LuminaryTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isActive;
  final int? maxLines;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const LuminaryTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isActive = false,
    this.maxLines = 1,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
  });

  @override
  State<LuminaryTextField> createState() => _LuminaryTextFieldState();
}

class _LuminaryTextFieldState extends State<LuminaryTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        setState(() => _isFocused = _focusNode.hasFocus);
      });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final isActive = _isFocused || widget.isActive;

    Color borderColor;
    List<BoxShadow>? shadows;

    if (hasError) {
      borderColor = AppColors.dustyRose;
      shadows = null;
    } else if (isActive) {
      borderColor = AppColors.warmAmber;
      shadows = [
        BoxShadow(
          color: AppColors.warmAmber,
          offset: AppDimensions.neoShadowOffset,
          blurRadius: AppDimensions.neoShadowBlur,
        ),
      ];
    } else {
      borderColor = AppColors.divider;
      shadows = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(widget.label, padding: const EdgeInsets.fromLTRB(0, 0, 0, 6)),
        Container(
          constraints: BoxConstraints(
            minHeight: AppDimensions.inputHeight,
          ),
          decoration: BoxDecoration(
            color: AppColors.bgWhite,
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
            border: Border.all(
              color: borderColor,
              width: isActive && !hasError ? 2.5 : 2,
            ),
            boxShadow: shadows,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            maxLines: widget.maxLines,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              widget.errorText!,
              style: AppTextStyles.caption.copyWith(color: AppColors.dustyRose),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
