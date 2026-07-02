import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LoadingSkeleton extends StatefulWidget {
  final int itemCount;
  final double itemHeight;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const LoadingSkeleton({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.borderRadius = 12,
    this.padding,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.shimmerBase : const Color(0xFFE5E7EB);
    final highlightColor = isDark ? AppColors.shimmerHighlight : const Color(0xFFF3F4F6);

    return ListView.builder(
      padding: widget.padding ?? const EdgeInsets.all(16),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return _ShimmerAnimation(
          listenable: _animation,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              height: widget.itemHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                gradient: LinearGradient(
                  colors: [baseColor, highlightColor, baseColor],
                  stops: const [0.0, 0.5, 1.0],
                  begin: Alignment(-1.0 + _animation.value, 0.0),
                  end: Alignment(1.0 + _animation.value, 0.0),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ShimmerBlock extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;

  const ShimmerBlock({
    super.key,
    this.height = 16,
    this.width = double.infinity,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: isDark ? AppColors.shimmerBase : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class _ShimmerAnimation extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;

  const _ShimmerAnimation({
    required super.listenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}
