import 'package:flutter/material.dart';
import 'package:smartstock/core/constants/color_constants.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/utils/date_utils.dart';
import 'package:smartstock/features/reports/models/report_model.dart';

class SalesBarChart extends StatelessWidget {
  final List<SalesReport> data;
  final String title;
  final double maxBarHeight;

  const SalesBarChart({
    super.key,
    required this.data,
    required this.title,
    this.maxBarHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = data.fold<double>(
      0,
      (max, r) => r.totalSales > max ? r.totalSales : max,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleMd,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: maxBarHeight + 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(data.length, (index) {
              final report = data[index];
              final barHeight = maxValue > 0
                  ? (report.totalSales / maxValue) * maxBarHeight
                  : 0.0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '\$${report.totalSales.toStringAsFixed(0)}',
                        style: AppTextStyles.labelSm.copyWith(
                          fontSize: 9,
                          color: ColorConstants.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: barHeight.clamp(4.0, maxBarHeight),
                        decoration: BoxDecoration(
                          color: ColorConstants.primary.withValues(
                            alpha: 0.6 + (0.4 * (index / data.length)),
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatLabel(report.date),
                        style: AppTextStyles.labelSm.copyWith(
                          fontSize: 9,
                          color: ColorConstants.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  String _formatLabel(DateTime date) {
    if (data.length <= 7) {
      return AppDateUtils.formatDate(date);
    }
    return '${date.day}/${date.month}';
  }
}

class SimpleBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;
  final String Function(double value)? formatValue;

  const SimpleBar({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    this.color = ColorConstants.primary,
    this.formatValue,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue > 0 ? value / maxValue : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatValue?.call(value) ?? value.toStringAsFixed(2),
              style: AppTextStyles.labelMd.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: ColorConstants.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
