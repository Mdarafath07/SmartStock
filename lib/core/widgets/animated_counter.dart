import 'package:flutter/material.dart';

class AnimatedCounter extends StatefulWidget {
  final double target;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final int decimals;

  const AnimatedCounter({
    super.key,
    required this.target,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _startValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _startValue = _animation.value * oldWidget.target;
      _controller.reset();
      _controller.forward();
    }
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
      builder: (_, child) {
        final val = _startValue + (widget.target - _startValue) * _animation.value;
        final formatted = val.toStringAsFixed(widget.decimals);
        return Text('${widget.prefix}$formatted${widget.suffix}', style: widget.style);
      },
    );
  }
}
