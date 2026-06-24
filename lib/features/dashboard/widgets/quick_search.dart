import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartstock/core/constants/app_constants.dart';
import 'package:smartstock/core/theme/app_colors.dart';

class QuickSearch extends StatefulWidget {
  const QuickSearch({super.key});

  @override
  State<QuickSearch> createState() => _QuickSearchState();
}

class _QuickSearchState extends State<QuickSearch> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final q = query.trim().toLowerCase();
    FirebaseFirestore.instance
        .collection('products')
        .limit(AppConstants.quickSearchMaxResults)
        .get()
        .then((snapshot) {
      final filtered = snapshot.docs.where((doc) {
        final data = doc.data();
        final name =
            (data['name'] as String? ?? '').toLowerCase();
        final model =
            (data['modelNumber'] as String? ?? '').toLowerCase();
        return name.contains(q) || model.contains(q);
      }).map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (!mounted) return;
      setState(() {
        _results = filtered;
        _isSearching = false;
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _isSearching = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search products, model, serial...',
                prefixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _search('');
                        },
                      )
                    : null,
              ),
              onChanged: _search,
            ),
          ),
          if (_results.isEmpty && _controller.text.isNotEmpty && !_isSearching)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No products found',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final product = _results[index];
                return _buildResultItem(context, product);
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 16),
        ],
      ),
    );
  }

  Widget _buildResultItem(BuildContext context, Map<String, dynamic> product) {
    final availableQty =
        (product['availableQuantity'] as num?)?.toInt() ?? 0;
    final status = availableQty == 0
        ? 'Out of Stock'
        : availableQty <= AppConstants.lowStockThreshold
            ? 'Low Stock'
            : 'In Stock';
    final statusColor = availableQty == 0
        ? AppColors.statusOutOfStock
        : availableQty <= AppConstants.lowStockThreshold
            ? AppColors.statusLowStock
            : AppColors.statusInStock;
    final statusBg = availableQty == 0
        ? AppColors.statusOutOfStockBg
        : availableQty <= AppConstants.lowStockThreshold
            ? AppColors.statusLowStockBg
            : AppColors.statusInStockBg;

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: product['imageUrl'] != null &&
                (product['imageUrl'] as String).isNotEmpty
            ? CachedNetworkImage(
                imageUrl: product['imageUrl'] as String,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
placeholder: (_, _) => Container(
    color: AppColors.surfaceContainerHighest,
    child: const Icon(Icons.image)),
errorWidget: (_, _, _) => Container(
    color: AppColors.surfaceContainerHighest,
    child: const Icon(Icons.image)),
              )
            : Container(
                width: 48,
                height: 48,
                color: AppColors.surfaceContainerHighest,
                child: const Icon(Icons.image),
              ),
      ),
      title: Text(
        product['name'] as String? ?? '',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        product['modelNumber'] as String? ?? '',
        style: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 12,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$availableQty',
            style: const TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }
}
