import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RpMiniPin extends StatelessWidget {
  const RpMiniPin({
    super.key,
    required this.index,
    this.selected = false,
    this.onPressed,
  });

  final int index;
  final bool selected;
  final VoidCallback? onPressed;

  static const _pinWidth = 32.0;
  static const _bodyHeight = 26.0;
  static const _tailSize = 8.0;
  static const _borderWidth = 2.0;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.primary;
    final bg = selected ? AppColors.primary : Colors.white;
    final borderColor = selected ? Colors.white : AppColors.primary;
    final shadow = selected
        ? const BoxShadow(
            color: Color(0x806C3FC5),
            blurRadius: 16,
            offset: Offset(0, 6),
          )
        : const BoxShadow(
            color: Color(0x26000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          );

    return Semantics(
      button: onPressed != null,
      label: 'Parada $index${selected ? ', selecionada' : ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: _pinWidth,
          height: _bodyHeight + _tailSize / 2,
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                bottom: 0,
                child: Transform.translate(
                  offset: const Offset(0, _tailSize / 2),
                  child: Transform.rotate(
                    angle: math.pi / 4,
                    child: Container(
                      width: _tailSize,
                      height: _tailSize,
                      decoration: BoxDecoration(
                        color: bg,
                        border: Border(
                          right: BorderSide(
                            color: borderColor,
                            width: _borderWidth,
                          ),
                          bottom: BorderSide(
                            color: borderColor,
                            width: _borderWidth,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 22),
                height: _bodyHeight,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: bg,
                  border: Border.all(color: borderColor, width: _borderWidth),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [shadow],
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: fg,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
