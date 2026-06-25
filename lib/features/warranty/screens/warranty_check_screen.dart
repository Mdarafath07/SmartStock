import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/widgets/empty_state.dart';
import 'package:smartstock/core/widgets/error_widget.dart';
import 'package:smartstock/features/warranty/providers/warranty_provider.dart';
import 'package:smartstock/features/warranty/widgets/warranty_card.dart';
import 'package:smartstock/features/warranty/widgets/warranty_search_bar.dart';

class WarrantyCheckScreen extends StatefulWidget {
  const WarrantyCheckScreen({super.key});

  @override
  State<WarrantyCheckScreen> createState() => _WarrantyCheckScreenState();
}

class _WarrantyCheckScreenState extends State<WarrantyCheckScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WarrantyProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warranty Check'),
      ),
      body: Consumer<WarrantyProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              WarrantySearchBar(
                onSerialChanged: (value) => provider.search(value),
                onModelChanged: (value) => provider.search(value),
                onCategoryChanged: (value) => provider.search(value),
              ),
              const SizedBox(height: 8),
              _buildTabRow(provider),
              const SizedBox(height: 8),
              Expanded(child: _buildContent(provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabRow(WarrantyProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _filterChip('All', provider.searchResults.isEmpty, () {
            provider.loadAll();
          }),
          const SizedBox(width: 8),
          _filterChip('Active', false, () {
            provider.loadActive();
          }),
          const SizedBox(width: 8),
          _filterChip('Expired', false, () {
            provider.loadExpired();
          }),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      labelStyle: AppTextStyles.labelMd,
    );
  }

  Widget _buildContent(WarrantyProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return AppErrorWidget(
        message: provider.error!,
        onRetry: () => provider.loadAll(),
      );
    }

    final warranties = provider.searchResults.isNotEmpty
        ? provider.searchResults
        : provider.warranties;

    if (warranties.isEmpty) {
      return EmptyState(
        icon: Icons.verified_user_rounded,
        title: 'No Warranties Found',
        subtitle: 'Warranties from sales will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadAll(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: warranties.length,
        itemBuilder: (context, index) {
          final warranty = warranties[index];
          return WarrantyCard(
            warranty: warranty,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/warranty/details',
                arguments: warranty.id,
              );
            },
            onClaim: warranty.isClaimable
                ? () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/warranty/claim',
                      arguments: warranty,
                    );
                    if (result == true) {
                      provider.loadAll();
                    }
                  }
                : null,
          );
        },
      ),
    );
  }
}
