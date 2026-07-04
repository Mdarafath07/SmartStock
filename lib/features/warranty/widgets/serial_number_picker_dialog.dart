import 'package:flutter/material.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/features/warranty/services/warranty_service.dart';

class SerialNumberPickerDialog extends StatefulWidget {
  const SerialNumberPickerDialog({super.key});

  @override
  State<SerialNumberPickerDialog> createState() =>
      _SerialNumberPickerDialogState();
}

class _SerialNumberPickerDialogState extends State<SerialNumberPickerDialog> {
  final _searchCtrl = TextEditingController();
  final _service = WarrantyService();
  List<Map<String, String>> _allSerials = [];
  List<Map<String, String>> _filteredSerials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSerials();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSerials() async {
    try {
      final serials = await _service.getAvailableSerials();
      if (mounted) {
        setState(() {
          _allSerials = serials;
          _filteredSerials = serials;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filter(String query) {
    final lower = query.toLowerCase();
    setState(() {
      _filteredSerials = _allSerials.where((s) {
        return s['serialNumber']!.toLowerCase().contains(lower) ||
            s['productName']!.toLowerCase().contains(lower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      title: const Text('Select Replacement Serial'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _allSerials.isEmpty
                ? const Center(child: Text('No available serials in stock'))
                : Column(
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Search by serial or product name...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: _filter,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_filteredSerials.length} available serial(s)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.textSecondary : const Color(0xFF454652),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _filteredSerials.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _filteredSerials[index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                item['serialNumber']!,
                                style: const TextStyle(
                                  fontFamily: 'Geist',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                item['productName']!,
                                style: const TextStyle(fontSize: 12),
                              ),
                              leading: const Icon(
                                Icons.qr_code_2,
                                color: AppColors.primary,
                              ),
                              onTap: () =>
                                  Navigator.pop(context, item['serialNumber']!),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
      actions: [
        Debounced(
          onPressed: () => Navigator.pop(context),
          builder: (_, isDisabled) => TextButton(
            onPressed: isDisabled ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }
}
