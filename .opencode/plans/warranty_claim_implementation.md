# Warranty Claim Implementation Plan

## Overview
8 file changes to add "Claim Warranty" flow on sale details + warranty details + warranty card.

---

## 1. `lib/features/sales/models/sale_model.dart`

### Changes
- Add `bool warrantyClaimed = false` field
- Add `bool get isWarrantyClaimable` getter

### Code

```dart
// After line: final String? oldSerialNumber;
final bool warrantyClaimed;

// In constructor, add: this.warrantyClaimed = false,

// In fromJson, add:
warrantyClaimed: json['warrantyClaimed'] as bool? ?? false,

// In toJson, add:
'warrantyClaimed': warrantyClaimed,

// In copyWith, add:
bool? warrantyClaimed,

// In copyWith return, add:
warrantyClaimed: warrantyClaimed ?? this.warrantyClaimed,

// Add getter after isWarrantyClaim:
bool get isWarrantyClaimable =>
    saleType == 'normal' && warrantyExpiryDate.isAfter(DateTime.now()) && !warrantyClaimed;
```

---

## 2. `lib/features/warranty/models/warranty_model.dart`

### Changes
- Add `bool warrantyClaimed = false` field
- Add `bool get isClaimable` getter

### Code

```dart
// After line: final double salePrice;
final bool warrantyClaimed;

// In const constructor, add: this.warrantyClaimed = false,

// In fromJson, add:
warrantyClaimed: json['warrantyClaimed'] as bool? ?? false,

// In toJson, add:
'warrantyClaimed': warrantyClaimed,

// In copyWith, add:
bool? warrantyClaimed,

// In copyWith return:
warrantyClaimed: warrantyClaimed ?? this.warrantyClaimed,

// Add getter after isActive:
bool get isClaimable => isActive && !warrantyClaimed;
```

---

## 3. `lib/features/warranty/screens/warranty_claim_screen.dart`

### Changes
- Add `_reasonController` text field
- Pass reason to `processClaim` as `notes`
- Helper text for reason field

### Code

```dart
// Add controller after _notesController:
final _reasonController = TextEditingController();

// In dispose:
_reasonController.dispose();

// In _submit, add to processClaim:
reason: _reasonController.text.trim(),

// In build, add Reason field before New Serial Number:
TextFormField(
  controller: _reasonController,
  decoration: const InputDecoration(
    labelText: 'Warranty Claim Reason',
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.description),
  ),
  maxLines: 2,
  validator: (v) =>
      (v == null || v.trim().isEmpty) ? 'Reason is required' : null,
),
const SizedBox(height: 16),
```

---

## 4. `lib/features/warranty/widgets/warranty_card.dart`

### Changes
- Add `VoidCallback? onClaim` parameter
- Add "Claim Warranty" button inside card bottom (if isClaimable)

### Code

```dart
// Add param to constructor:
final VoidCallback? onClaim;

// In build, after the Row(calendar) closing:
if (warranty.isClaimable && onClaim != null) ...[
  const SizedBox(height: 12),
  SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onClaim,
      icon: const Icon(Icons.assignment, size: 18),
      label: const Text('Claim Warranty'),
    ),
  ),
],
```

---

## 5. `lib/features/warranty/screens/warranty_check_screen.dart`

### Changes
- Remove the external `Column` wrapper and Process Claim button
- Pass `onClaim` to `WarrantyCard`

### Code

Replace the list item builder:
```dart
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
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    WarrantyClaimScreen(warranty: warranty),
              ),
            );
            if (result == true) {
              provider.loadAll();
            }
          }
        : null,
  );
},
```

Remove the `import 'package:smartstock/features/warranty/screens/warranty_claim_screen.dart';` line (it's no longer needed in this file).

---

## 6. `lib/features/warranty/screens/warranty_details_screen.dart`

### Changes
- Add "Claim Your Warranty" button at bottom (if isClaimable)
- After claim → reload and show old/new product details + reason
- Add `_isClaiming` state + `_claimResult` state

### Code

```dart
// Add state variables after initState:
bool _isClaiming = false;
Map<String, dynamic>? _claimResult;

// Add _claim() method:
Future<void> _claim() async {
  final w = context.read<WarrantyProvider>().selectedWarranty;
  if (w == null) return;

  final newSerial = await showDialog<String>(
    context: context,
    builder: (ctx) => _ClaimFormDialog(),
  );
  if (newSerial == null) return;

  setState(() => _isClaiming = true);
  try {
    await context.read<WarrantyProvider>().processClaim(
      saleId: w.saleId,
      serialNumber: w.serialNumber,
      newSerialNumber: newSerial,
      notes: 'Claimed from warranty details',
    );
    setState(() {
      _claimResult = {'newSerial': newSerial};
    });
    if (mounted) {
      context.read<WarrantyProvider>().loadBySaleId(widget.warrantyId);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => _isClaiming = false);
  }
}

// After _buildTimeline(warranty), add:
if (warranty.isClaimable) ...[
  const SizedBox(height: 20),
  SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: _isClaiming ? null : _claim,
      icon: _isClaiming
          ? const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.verified_user),
      label: const Text('Claim Your Warranty'),
    ),
  ),
],
// Show claim result if present
if (_claimResult != null) ...[
  const SizedBox(height: 20),
  Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Warranty Claimed',
              style: AppTextStyles.titleMd.copyWith(color: ColorConstants.success)),
          const SizedBox(height: 8),
          Text('Old Serial: ${warranty.serialNumber} → Available',
              style: AppTextStyles.bodyMd),
          Text('New Serial: ${_claimResult!['newSerial']} → Sold (Warranty)',
              style: AppTextStyles.bodyMd),
        ],
      ),
    ),
  ),
],

// Add _ClaimFormDialog widget at bottom:
class _ClaimFormDialog extends StatefulWidget {
  @override
  State<_ClaimFormDialog> createState() => _ClaimFormDialogState();
}
class _ClaimFormDialogState extends State<_ClaimFormDialog> {
  final _serialCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  @override
  void dispose() { _serialCtrl.dispose(); _reasonCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Claim Warranty'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _serialCtrl,
            decoration: const InputDecoration(
              labelText: 'New Serial Number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonCtrl,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _serialCtrl.text.trim()),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
```

---

## 7. `lib/features/sales/screens/sale_details_screen.dart`

### Changes
- Replace entire warranty progress card with:
  - If `warrantyClaimed`: claimed info card (old serial → available, new serial → sold by warranty, link to claim sale)
  - Else if `isWarrantyClaimable`: "Claim Warranty" button → navigates to WarrantyDetailsScreen
  - Else: simple expired/active badge

### Code

```dart
// Add import at top:
import 'package:smartstock/features/warranty/screens/warranty_details_screen.dart';

// Replace the entire warranty card (lines ~183-229) with:
Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Warranty Information',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            if (sale.warrantyClaimed)
              _badge('Claimed', Colors.grey)
            else if (isWarrantyValid)
              _badge('Active', Colors.green)
            else
              _badge('Expired', Colors.red),
          ],
        ),
        const SizedBox(height: 12),
        if (sale.warrantyClaimed) ...[
          _buildInfoRow(theme, 'Old Serial', sale.serialNumber),
          _buildInfoRow(theme, 'Status', 'Returned (Available)'),
          if (sale.relatedSaleId != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<SaleProvider>().loadSaleById(sale.relatedSaleId!);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SaleDetailsScreen(saleId: sale.relatedSaleId!),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt, size: 18),
                label: const Text('View Claim Sale'),
              ),
            ),
          ],
        ] else if (isWarrantyValid) ...[
          _buildInfoRow(theme, 'Expiry Date',
              dateFormatter.format(sale.warrantyExpiryDate)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        WarrantyDetailsScreen(warrantyId: sale.id),
                  ),
                );
              },
              icon: const Icon(Icons.verified_user),
              label: const Text('Claim Warranty'),
            ),
          ),
        ] else ...[
          _buildInfoRow(theme, 'Expiry Date',
              dateFormatter.format(sale.warrantyExpiryDate)),
          _buildInfoRow(theme, 'Status', 'Warranty expired'),
        ],
      ],
    ),
  ),
),
```

Remove `final isWarrantyValid` computation at top OR keep it for the fallback.

---

## 8. `lib/features/warranty/services/warranty_service.dart`

### Changes (if not already present)
The `claimWarranty` method already sets `warrantyClaimed: true` on the original sale doc in the batch write. Add `'warrantyClaimed': true` to the old sale update:

```dart
// In claimWarranty method, step 6:
batch.update(saleDoc.reference, {
  'warrantyClaimed': true,
});
```

This should already be present. Verify.

---

## Summary

| # | File | Change |
|---|------|--------|
| 1 | `sale_model.dart` | +`warrantyClaimed` field + `isWarrantyClaimable` getter |
| 2 | `warranty_model.dart` | +`warrantyClaimed` field + `isClaimable` getter |
| 3 | `warranty_claim_screen.dart` | +Reason field, pass reason to processClaim |
| 4 | `warranty_card.dart` | +`onClaim` callback + "Claim Warranty" button inside card |
| 5 | `warranty_check_screen.dart` | Remove external column wrapper, pass `onClaim` to card |
| 6 | `warranty_details_screen.dart` | +"Claim Your Warranty" button, +claim result display |
| 7 | `sale_details_screen.dart` | Replace warranty card with claim flow |
| 8 | `warranty_service.dart` | Verify `warrantyClaimed: true` is set on batch |
