import 'package:flutter/material.dart';

class SkeletonWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonWidget({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 4,
  });

  @override
  State<SkeletonWidget> createState() => _SkeletonWidgetState();
}

class _SkeletonWidgetState extends State<SkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: _animation.value),
          ),
        );
      },
    );
  }
}

class TableSkeleton extends StatelessWidget {
  final int rows;
  final int columns;

  const TableSkeleton({
    super.key,
    this.rows = 5,
    this.columns = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        rows,
        (row) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: List.generate(
              columns,
              (col) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: col > 0 ? 8 : 0,
                    right: col < columns - 1 ? 8 : 0,
                  ),
                  child: SkeletonWidget(
                    height: 16,
                    borderRadius: 4,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CardSkeleton extends StatelessWidget {
  final bool hasImage;

  const CardSkeleton({
    super.key,
    this.hasImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage) ...[
              const SkeletonWidget(height: 120, borderRadius: 8),
              const SizedBox(height: 12),
            ],
            const SkeletonWidget(width: 200, height: 18),
            const SizedBox(height: 8),
            const SkeletonWidget(width: 140, height: 14),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonWidget(width: 80, height: 14),
                SkeletonWidget(width: 60, height: 24, borderRadius: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StatsGridSkeleton extends StatelessWidget {
  const StatsGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: List.generate(
          4,
          (_) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SkeletonWidget(width: 32, height: 32, borderRadius: 8),
                  const SizedBox(height: 12),
                  const SkeletonWidget(width: 60, height: 24),
                  const SizedBox(height: 4),
                  const SkeletonWidget(width: 100, height: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
