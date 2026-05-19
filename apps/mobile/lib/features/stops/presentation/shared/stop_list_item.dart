import 'package:flutter/material.dart';

import '../../domain/stop.dart';

class StopListItem extends StatelessWidget {
  const StopListItem({
    super.key,
    required this.index,
    required this.stop,
    this.onTap,
    this.trailing,
  });

  final int index;
  final Stop stop;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Parada ${index + 1}: ${stop.label ?? "sem rótulo"}',
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(radius: 16, child: Text('${index + 1}')),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    stop.label ??
                        '${stop.lat.toStringAsFixed(5)}, ${stop.lng.toStringAsFixed(5)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
