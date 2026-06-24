import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstock/core/constants/color_constants.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/widgets/empty_state.dart';
import 'package:smartstock/features/search/widgets/search_result_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().isEmpty) {
        setState(() {
          _results = [];
          _isSearching = false;
        });
        return;
      }
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    setState(() => _isSearching = true);

    try {
      final results = <Map<String, dynamic>>[];
      final queryLower = query.toLowerCase();

      final futures = await Future.wait([
        _searchProducts(queryLower),
        _searchCustomers(queryLower),
        _searchSales(queryLower),
      ]);

      for (final list in futures) {
        results.addAll(list);
      }

      results.sort((a, b) {
        final aRelevance = _relevance(a['title'] as String, query);
        final bRelevance = _relevance(b['title'] as String, query);
        return bRelevance.compareTo(aRelevance);
      });

      if (!mounted) return;
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }

  int _relevance(String title, String query) {
    final lower = title.toLowerCase();
    if (lower.startsWith(query)) return 10;
    if (lower.contains(query)) return 5;
    return 0;
  }

  Future<List<Map<String, dynamic>>> _searchProducts(String query) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .orderBy('name')
        .get();

    return snapshot.docs
        .where((doc) {
          final data = doc.data();
          final name = (data['name'] as String? ?? '').toLowerCase();
          final model = (data['modelNumber'] as String? ?? '').toLowerCase();
          return name.contains(query) || model.contains(query);
        })
        .map((doc) {
          final data = doc.data();
          return {
            'title': data['name'] as String? ?? '',
            'subtitle': 'Model: ${data['modelNumber'] ?? ''}',
            'type': 'product',
            'icon': Icons.inventory_2_rounded,
            'route': '/products/details',
            'id': doc.id,
          };
        })
        .take(5)
        .toList();
  }

  Future<List<Map<String, dynamic>>> _searchCustomers(String query) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('customers')
        .orderBy('name')
        .get();

    return snapshot.docs
        .where((doc) {
          final data = doc.data();
          final name = (data['name'] as String? ?? '').toLowerCase();
          final phone = (data['phone'] as String? ?? '').toLowerCase();
          return name.contains(query) || phone.contains(query);
        })
        .map((doc) {
          final data = doc.data();
          return {
            'title': data['name'] as String? ?? '',
            'subtitle': 'Phone: ${data['phone'] ?? ''}',
            'type': 'customer',
            'icon': Icons.person_rounded,
            'route': '/customers/details',
            'id': doc.id,
          };
        })
        .take(5)
        .toList();
  }

  Future<List<Map<String, dynamic>>> _searchSales(String query) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('sales')
        .orderBy('saleDate', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .where((doc) {
          final data = doc.data();
          final productName =
              (data['productName'] as String? ?? '').toLowerCase();
          final serial =
              (data['serialNumber'] as String? ?? '').toLowerCase();
          final customer =
              (data['customerName'] as String? ?? '').toLowerCase();
          return productName.contains(query) ||
              serial.contains(query) ||
              customer.contains(query);
        })
        .map((doc) {
          final data = doc.data();
          return {
            'title': '${data['productName'] ?? ''} - ${data['customerName'] ?? ''}',
            'subtitle': 'S/N: ${data['serialNumber'] ?? ''}',
            'type': 'sale',
            'icon': Icons.receipt_long_rounded,
            'route': '/sales/details',
            'id': doc.id,
          };
        })
        .take(5)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final groupedResults = _groupResults();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(
                hintText: 'Search products, customers, sales...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                isDense: true,
              ),
            ),
          ),
          Expanded(child: _buildResults(groupedResults)),
        ],
      ),
    );
  }

  List<MapEntry<String, List<Map<String, dynamic>>>> _groupResults() {
    if (_results.isEmpty) return [];

    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final item in _results) {
      final type = (item['type'] as String).toUpperCase();
      grouped.putIfAbsent(type, () => []);
      grouped[type]!.add(item);
    }

    return grouped.entries.toList();
  }

  Widget _buildResults(
      List<MapEntry<String, List<Map<String, dynamic>>>> grouped) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.trim().isEmpty) {
      return EmptyState(
        icon: Icons.search_rounded,
        title: 'Search Everything',
        subtitle:
            'Search for products, customers, and sales records across your inventory.',
      );
    }

    if (grouped.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No Results Found',
        subtitle: 'Try a different search term.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: grouped.length,
      itemBuilder: (context, sectionIndex) {
        final section = grouped[sectionIndex];
        final items = section.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                section.key,
                style: AppTextStyles.labelMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...items.map((item) => SearchResultTile(
                  leadingIcon: item['icon'] as IconData,
                  title: item['title'] as String,
                  subtitle: item['subtitle'] as String,
                  type: item['type'] as String,
                  onTap: () {
                    final route = item['route'] as String;
                    final id = item['id'] as String;
                    Navigator.pushNamed(context, route, arguments: id);
                  },
                )),
          ],
        );
      },
    );
  }
}
