import 'package:flutter/material.dart';
import '../theme/text_styles.dart';

class SearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool autofocus;
  final FocusNode? focusNode;

  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search...',
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _showClear = widget.controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _showClear) {
      setState(() => _showClear = hasText);
    }
  }

  void _onClear() {
    widget.controller.clear();
    widget.onChanged('');
    widget.focusNode?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      style: AppTextStyles.bodyMd,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _showClear
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _onClear,
                splashRadius: 20,
              )
            : null,
        isDense: true,
      ),
    );
  }
}
