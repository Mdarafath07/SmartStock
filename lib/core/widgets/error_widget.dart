import 'package:flutter/material.dart';
import '../constants/color_constants.dart';
import '../theme/text_styles.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ColorConstants.errorContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: ColorConstants.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: AppTextStyles.titleMd.copyWith(
                color: ColorConstants.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMd.copyWith(
                color: ColorConstants.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
