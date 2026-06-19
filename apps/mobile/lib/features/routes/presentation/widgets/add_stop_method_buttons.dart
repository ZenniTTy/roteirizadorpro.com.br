import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_snackbar.dart';

class AddStopMethodButtons extends StatelessWidget {
  const AddStopMethodButtons({super.key});

  void _onShowStub(BuildContext context, String feature) {
    showAppSnackBar(context, '$feature em breve...');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _MethodButton(
            icon: LucideIcons.mapPin,
            label: 'Mapa',
            onTap: () => context.push('/home/routes/add-stop/map'),
          ),
          const SizedBox(width: 12),
          _MethodButton(
            icon: LucideIcons.scanLine, // fileText or scanLine for OCR
            label: 'Leitor',
            onTap: () => _onShowStub(context, 'Leitor OCR'),
          ),
          const SizedBox(width: 12),
          _MethodButton(
            icon: LucideIcons.mic,
            label: 'Voz',
            onTap: () => _onShowStub(context, 'Comando de Voz'),
          ),
        ],
      ),
    );
  }
}

class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3D6C3FC5),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: Colors.white),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
