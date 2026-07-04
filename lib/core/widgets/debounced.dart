import 'package:flutter/material.dart';

class Debounced extends StatefulWidget {
  final Widget Function(BuildContext, bool isDisabled) builder;
  final VoidCallback? onPressed;
  final Duration delay;

  const Debounced({
    super.key,
    required this.builder,
    this.onPressed,
    this.delay = const Duration(seconds: 3),
  });

  @override
  State<Debounced> createState() => _DebouncedState();
}

class _DebouncedState extends State<Debounced> {
  bool _isPressed = false;

  void _handleTap() {
    if (_isPressed || widget.onPressed == null) return;
    setState(() => _isPressed = true);
    widget.onPressed!();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _isPressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onPressed == null) {
      return widget.builder(context, true);
    }
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: widget.builder(context, _isPressed),
    );
  }
}
