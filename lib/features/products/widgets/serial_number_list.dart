import 'package:flutter/material.dart';
import 'package:smartstock/core/theme/app_colors.dart';

class SerialNumberList extends StatelessWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(int index) onScan;

  const SerialNumberList({
    super.key,
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Serial Numbers',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(controllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controllers[index],
                    decoration: InputDecoration(
                      hintText: 'Serial number ${index + 1}',
                      hintStyle: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.primaryContainer,
                          width: 1,
                        ),
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 13,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => onScan(index),
                  icon: const Icon(
                    Icons.qr_code_scanner,
                    color: AppColors.primaryContainer,
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Scan barcode',
                ),
                if (controllers.length > 1) ...[
                  const SizedBox(width: 2),
                  IconButton(
                    onPressed: () => onRemove(index),
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: AppColors.error,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text(
            'Add Serial Number',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryContainer,
          ),
        ),
      ],
    );
  }
}
