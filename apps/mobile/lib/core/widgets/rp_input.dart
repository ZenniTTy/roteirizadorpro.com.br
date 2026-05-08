import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RpInput extends StatefulWidget {
  const RpInput({
    super.key,
    this.label,
    this.controller,
    this.placeholder,
    this.keyboardType,
    this.obscureText = false,
    this.prefix,
    this.suffix,
    this.error,
    this.onChanged,
    this.textInputAction,
    this.autofillHints,
  });

  final String? label;
  final TextEditingController? controller;
  final String? placeholder;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final String? error;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  @override
  State<RpInput> createState() => _RpInputState();
}

class _RpInputState extends State<RpInput> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocus);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocus)
      ..dispose();
    super.dispose();
  }

  void _handleFocus() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null && widget.error!.isNotEmpty;
    final borderColor = hasError
        ? AppColors.error
        : _focused
            ? AppColors.primary
            : AppColors.border;
    final fillColor = _focused ? AppColors.bg : AppColors.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.label!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(AppRadii.input),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: _focused && !hasError ? AppShadows.inputFocus : null,
          ),
          child: Row(
            children: [
              if (widget.prefix != null) ...[
                DefaultTextStyle.merge(
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                  child: widget.prefix!,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextField(
                  focusNode: _focusNode,
                  controller: widget.controller,
                  keyboardType: widget.keyboardType,
                  obscureText: widget.obscureText,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  onChanged: widget.onChanged,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.text,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.placeholder,
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (widget.suffix != null) ...[
                const SizedBox(width: 8),
                widget.suffix!,
              ],
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.error!,
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }
}
