import 'package:flutter/material.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
class GlobalSearch extends StatefulWidget {
  const GlobalSearch({super.key});

  @override
  State<GlobalSearch> createState() => _GlobalSearchState();
}

class _GlobalSearchState extends State<GlobalSearch> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _searchQuery = '';
  final List<String> _recentSearches = [
    'iPhone 15',
    'Samsung TV',
    'Warranty claims',
  ];

  final List<_SearchCategory> _categories = [
    _SearchCategory('Products', Icons.inventory_2_rounded, AppColors.primary),
    _SearchCategory('Categories', Icons.category_rounded, AppColors.blue),
    _SearchCategory('Warranty', Icons.verified_rounded, AppColors.orange),
    _SearchCategory('Sales', Icons.receipt_rounded, AppColors.purple),
    _SearchCategory('Customers', Icons.people_rounded, AppColors.primary),
    _SearchCategory('Issues', Icons.bug_report_rounded, AppColors.red),
  ];

  final List<_SearchResult> _mockResults = [
    _SearchResult('iPhone 15 Pro Max', 'Products', 'Smartphone, 256GB', Icons.phone_iphone_rounded, AppColors.primary, AppRoutes.productsDetails),
    _SearchResult('Samsung 65" TV', 'Products', 'OLED, 4K Smart TV', Icons.tv_rounded, AppColors.primary, AppRoutes.productsDetails),
    _SearchResult('Warranty - iPhone 15', 'Warranty', 'Expires in 300 days', Icons.verified_rounded, AppColors.orange, AppRoutes.warrantyDetails),
    _SearchResult('Sale #2024-001', 'Sales', '\$1,299 - John Doe', Icons.receipt_rounded, AppColors.purple, AppRoutes.salesDetails),
    _SearchResult('John Doe', 'Customers', 'john@email.com', Icons.person_rounded, AppColors.blue, AppRoutes.customersDetails),
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(isDark),
          _buildSearchField(isDark),
          Expanded(
            child: _searchQuery.isEmpty ? _buildInitialView(isDark) : _buildResultsView(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _searchQuery.isNotEmpty
                ? AppColors.primary.withAlpha(100)
                : (isDark ? AppColors.greyDarker.withAlpha(80) : const Color(0xFFE5E7EB)),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.search_rounded,
              size: 20,
              color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search products, sales, customers...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear_rounded, size: 18, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialView(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (_recentSearches.isNotEmpty) ...[
          _buildSectionHeader('Recent Searches', isDark),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((s) => _RecentSearchChip(text: s, isDark: isDark, onTap: () {
              _searchController.text = s;
              setState(() => _searchQuery = s);
            })).toList(),
          ),
          const SizedBox(height: 24),
        ],
        _buildSectionHeader('Quick Filters', isDark),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            return GestureDetector(
              onTap: () {
                _searchController.text = cat.name;
                setState(() => _searchQuery = cat.name);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(180),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE5E7EB),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cat.color.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(cat.icon, size: 18, color: cat.color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat.name,
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Smart Suggestions', isDark),
        const SizedBox(height: 8),
        _SuggestionTile(
          icon: Icons.trending_up_rounded,
          title: 'Best Selling Products',
          subtitle: 'View top performing items',
          color: AppColors.green,
          isDark: isDark,
          onTap: () => Navigator.pushNamed(context, AppRoutes.products),
        ),
        _SuggestionTile(
          icon: Icons.inventory_rounded,
          title: 'Low Stock Items',
          subtitle: 'Products needing restock',
          color: AppColors.orange,
          isDark: isDark,
          onTap: () => Navigator.pushNamed(context, AppRoutes.inventory),
        ),
        _SuggestionTile(
          icon: Icons.warning_rounded,
          title: 'Warranty Expiring Soon',
          subtitle: '7 items expiring this month',
          color: AppColors.red,
          isDark: isDark,
          onTap: () => Navigator.pushNamed(context, AppRoutes.warranty),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildResultsView(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        _buildSectionHeader('Results', isDark),
        const SizedBox(height: 4),
        Text(
          '${_mockResults.length} results found',
          style: AppTextStyles.caption.copyWith(
            color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 12),
        ..._mockResults.map((r) => _ResultTile(
              result: r,
              isDark: isDark,
              query: _searchQuery,
              onTap: () => Navigator.pushNamed(context, r.route),
            )),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.search);
            },
            child: Text(
              'View All Results',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: AppTextStyles.titleSm.copyWith(
        color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
      ),
    );
  }
}

class _SearchCategory {
  final String name;
  final IconData icon;
  final Color color;
  const _SearchCategory(this.name, this.icon, this.color);
}

class _SearchResult {
  final String title;
  final String category;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  const _SearchResult(this.title, this.category, this.subtitle, this.icon, this.color, this.route);
}

class _RecentSearchChip extends StatelessWidget {
  final String text;
  final bool isDark;
  final VoidCallback onTap;

  const _RecentSearchChip({required this.text, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(180),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE5E7EB),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 14, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
            const SizedBox(width: 6),
            Text(
              text,
              style: AppTextStyles.labelSm.copyWith(
                color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const _SuggestionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: (isDark ? AppColors.surfaceLight : const Color(0xFFF9FAFB)).withAlpha(180),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
                  Text(subtitle, style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final _SearchResult result;
  final bool isDark;
  final String query;
  final VoidCallback onTap;

  const _ResultTile({required this.result, required this.isDark, required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: (isDark ? AppColors.surfaceLight : const Color(0xFFF9FAFB)).withAlpha(180),
        border: Border.all(
          color: isDark ? AppColors.greyDarker.withAlpha(40) : const Color(0xFFE5E7EB).withAlpha(80),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: result.color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(result.icon, size: 18, color: result.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: _highlightText(result.title, query, isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: result.color.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        result.category,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: result.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  List<TextSpan> _highlightText(String text, String query, bool isDark) {
    if (query.isEmpty) {
      return [TextSpan(text: text, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)))];
    }
    final lowercase = text.toLowerCase();
    final queryLower = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int index;
    while ((index = lowercase.indexOf(queryLower, start)) != -1) {
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
      ));
      start = index + query.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    final styled = spans.map((span) {
      final style = TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E));
      return TextSpan(text: span.text, style: span.style ?? style);
    }).toList();
    return styled;
  }
}
