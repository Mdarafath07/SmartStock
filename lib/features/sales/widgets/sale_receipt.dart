import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';

class ReceiptItem {
  final String productName;
  final String modelNumber;
  final String serialNumber;
  final double price;
  final int warrantyMonths;
  final DateTime warrantyExpiry;
  final DateTime saleDate;

  const ReceiptItem({
    required this.productName,
    required this.modelNumber,
    required this.serialNumber,
    required this.price,
    this.warrantyMonths = 0,
    required this.warrantyExpiry,
    required this.saleDate,
  });
}

void showSaleReceipt(BuildContext context, {
  required String customerName,
  required String customerPhone,
  required List<ReceiptItem> items,
  required VoidCallback onDone,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => _ReceiptScreen(
        customerName: customerName,
        customerPhone: customerPhone,
        items: items,
        onDone: onDone,
      ),
    ),
  );
}

class _ReceiptScreen extends StatelessWidget {
  final String customerName;
  final String customerPhone;
  final List<ReceiptItem> items;
  final VoidCallback onDone;

  const _ReceiptScreen({
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.read<SettingsProvider>();
    final symbol = settings.currencySymbol;
    final storeName = settings.storeName;
    final dateStr = DateFormat('MMM dd, yyyy').format(items.first.saleDate);
    final timeStr = DateFormat('hh:mm a').format(items.first.saleDate);
    final total = items.fold(0.0, (s, i) => s + i.price);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : const Color(0xFF475569)),
          onPressed: () { Navigator.pop(context); onDone(); },
        ),
        title: Text('Receipt', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF475569))),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(
            width: 320,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(storeName, style: TextStyle(fontFamily: 'Geist', fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                Text('INVOICE', style: TextStyle(fontFamily: 'Geist', fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 4, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
                const SizedBox(height: 16),
                _dashedLine(isDark),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Date', style: TextStyle(fontFamily: 'Geist', fontSize: 10, color: isDark ? Colors.white54 : const Color(0xFF6B7280))),
                    Text(dateStr, style: TextStyle(fontFamily: 'Geist', fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Time', style: TextStyle(fontFamily: 'Geist', fontSize: 10, color: isDark ? Colors.white54 : const Color(0xFF6B7280))),
                    Text(timeStr, style: TextStyle(fontFamily: 'Geist', fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Customer', style: TextStyle(fontFamily: 'Geist', fontSize: 10, color: isDark ? Colors.white54 : const Color(0xFF6B7280))),
                    Text(customerName, style: TextStyle(fontFamily: 'Geist', fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                  ],
                ),
                if (customerPhone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Phone', style: TextStyle(fontFamily: 'Geist', fontSize: 10, color: isDark ? Colors.white54 : const Color(0xFF6B7280))),
                      Text(customerPhone, style: TextStyle(fontFamily: 'Geist', fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                _dashedLine(isDark),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(flex: 3, child: Text('ITEM', style: TextStyle(fontFamily: 'Geist', fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: isDark ? Colors.white54 : const Color(0xFF6B7280)))),
                    Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Geist', fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: isDark ? Colors.white54 : const Color(0xFF6B7280)))),
                    Expanded(flex: 2, child: Text('PRICE', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Geist', fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: isDark ? Colors.white54 : const Color(0xFF6B7280)))),
                  ],
                ),
                const SizedBox(height: 6),
                ...items.asMap().entries.map((e) {
                  final item = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(flex: 3, child: Text(item.productName, style: TextStyle(fontFamily: 'Geist', fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A2E)))),
                            Expanded(flex: 1, child: Text('1', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Geist', fontSize: 10, color: isDark ? Colors.white : const Color(0xFF1A1A2E)))),
                            Expanded(flex: 2, child: Text('$symbol${item.price.toStringAsFixed(2)}', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Geist', fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1A1A2E)))),
                          ],
                        ),
                        Text('SN: ${item.serialNumber}', style: TextStyle(fontFamily: 'Geist', fontSize: 8, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
                        Text(item.modelNumber, style: TextStyle(fontFamily: 'Geist', fontSize: 8, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                _dashedLine(isDark),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL', style: TextStyle(fontFamily: 'Geist', fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                    Text('$symbol${total.toStringAsFixed(2)}', style: TextStyle(fontFamily: 'Geist', fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () { Navigator.pop(context); onDone(); },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Done', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dashedLine(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: CustomPaint(
            painter: _DashedLinePainter(isDark: isDark),
          ),
        );
      },
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final bool isDark;
  _DashedLinePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white24 : const Color(0xFFD1D5DB)
      ..strokeWidth = 1;

    const dashWidth = 8.0;
    const dashGap = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
