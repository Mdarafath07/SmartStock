import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/theme/app_colors.dart';
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
            'route': AppRoutes.productsDetails,
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
            'route': AppRoutes.customersDetails,
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
          if (data['saleType'] == 'warranty_claim') return false;
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
            'route': AppRoutes.salesDetails,
            'id': doc.id,
          };
        })
        .take(5)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupedResults = _groupResults();

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldBg : AppColors.whiteSoft,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Search',
                style: AppTextStyles.headlineMd.copyWith(
                  color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                style: AppTextStyles.bodyMd.copyWith(
                  color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                ),
                decoration: InputDecoration(
                  hintText: 'Search products, customers, sales...',
                  hintStyle: AppTextStyles.bodyMd.copyWith(
                    color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, size: 18,
                              color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? AppColors.surface : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.green.withAlpha(80), width: 1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(child: _buildResults(groupedResults, isDark)),
          ],
        ),
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
      List<MapEntry<String, List<Map<String, dynamic>>>> grouped, bool isDark) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: grouped.length,
      itemBuilder: (context, sectionIndex) {
        final section = grouped[sectionIndex];
        final items = section.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                children: [
                  Text(
                    section.key,
                    style: AppTextStyles.labelLg.copyWith(
                      color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${items.length}',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.textMuted : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
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
