import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/features/sales/services/printer_service.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';

class ReceiptItem {
  final String productName;
  final String modelNumber;
  final String serialNumber;
  final double price;
  final int warrantyMonths;
  final DateTime warrantyExpiry;
  final DateTime saleDate;
  final int quantity;

  const ReceiptItem({
    required this.productName,
    required this.modelNumber,
    required this.serialNumber,
    required this.price,
    this.warrantyMonths = 0,
    required this.warrantyExpiry,
    required this.saleDate,
    this.quantity = 1,
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

  String _getOrderId() {
    final r = Random();
    return 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}${r.nextInt(999)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.read<SettingsProvider>();
    final symbol = settings.currencySymbol;
    final storeName = settings.storeName;
    final storePhone = settings.storePhone;
    final storeAddress = settings.storeAddress;
    final storeEmail = settings.storeEmail;
    final dateStr = DateFormat('MMM dd, yyyy').format(items.first.saleDate);
    final timeStr = DateFormat('hh:mm a').format(items.first.saleDate);
    final total = items.fold(0.0, (s, i) => s + (i.price * i.quantity));
    final orderId = _getOrderId();

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
            width: 300,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
                Text(storeName,
                    style: TextStyle(
                      fontFamily: 'Geist', fontSize: 20, fontWeight: FontWeight.w900,
                      letterSpacing: 1, color: isDark ? Colors.white : AppColors.textPrimary,
                    )),
                if (storeAddress.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(storeAddress,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Geist', fontSize: 9, height: 1.4,
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                      )),
                ],
                if (storePhone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(storePhone,
                      style: TextStyle(
                        fontFamily: 'Geist', fontSize: 9,
                        color: isDark ? Colors.white38 : AppColors.textMuted,
                      )),
                ],
                if (storeEmail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(storeEmail,
                      style: TextStyle(
                        fontFamily: 'Geist', fontSize: 9,
                        color: isDark ? Colors.white38 : AppColors.textMuted,
                      )),
                ],
                const SizedBox(height: 10),
                Text('INVOICE',
                    style: TextStyle(
                      fontFamily: 'Geist', fontSize: 10, fontWeight: FontWeight.w600,
                      letterSpacing: 5, color: isDark ? Colors.white38 : AppColors.textMuted,
                    )),
                const SizedBox(height: 14),
                _dashedLine(isDark),
                const SizedBox(height: 10),
                _infoRow('Order', orderId, isDark),
                const SizedBox(height: 4),
                _infoRow('Date', dateStr, isDark),
                const SizedBox(height: 4),
                _infoRow('Time', timeStr, isDark),
                const SizedBox(height: 4),
                _infoRow('Customer', customerName, isDark),
                if (customerPhone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _infoRow('Phone', customerPhone, isDark),
                ],
                const SizedBox(height: 12),
                _dashedLine(isDark),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withAlpha(8) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text('ITEM',
                          style: TextStyle(fontFamily: 'Geist', fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1, color: isDark ? Colors.white54 : AppColors.textSecondary))),
                      Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Geist', fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1, color: isDark ? Colors.white54 : AppColors.textSecondary))),
                      Expanded(flex: 2, child: Text('AMOUNT', textAlign: TextAlign.right,
                          style: TextStyle(fontFamily: 'Geist', fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1, color: isDark ? Colors.white54 : AppColors.textSecondary))),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                ...items.asMap().entries.map((e) {
                  final item = e.value;
                  final isLast = e.key == items.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(item.productName,
                                  style: TextStyle(
                                    fontFamily: 'Geist', fontSize: 9, fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                  )),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('${item.quantity}', textAlign: TextAlign.center,
                                  style: TextStyle(fontFamily: 'Geist', fontSize: 9, color: isDark ? Colors.white : AppColors.textPrimary)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('$symbol${(item.price * item.quantity).toStringAsFixed(0)}', textAlign: TextAlign.right,
                                  style: TextStyle(fontFamily: 'Geist', fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary)),
                            ),
                          ],
                        ),
                        if (item.modelNumber.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text('Model: ${item.modelNumber}',
                                style: TextStyle(fontFamily: 'Geist', fontSize: 7, color: isDark ? Colors.white38 : AppColors.textMuted)),
                          ),
                        if (item.serialNumber.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text('SN: ${item.serialNumber}',
                                style: TextStyle(fontFamily: 'Geist', fontSize: 7, color: isDark ? Colors.white38 : AppColors.textMuted)),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 10),
                _dashedLine(isDark),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL',
                        style: TextStyle(fontFamily: 'Geist', fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1, color: isDark ? Colors.white : AppColors.textPrimary)),
                    Text('$symbol${total.toStringAsFixed(0)}',
                        style: TextStyle(fontFamily: 'Geist', fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Items',
                        style: TextStyle(fontFamily: 'Geist', fontSize: 9, color: isDark ? Colors.white54 : AppColors.textSecondary)),
                    Text('${items.fold(0, (s, i) => s + i.quantity)} ${items.fold(0, (s, i) => s + i.quantity) == 1 ? 'item' : 'items'}',
                        style: TextStyle(fontFamily: 'Geist', fontSize: 9, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF374151))),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Thank you for your purchase!',
                    style: TextStyle(fontFamily: 'Geist', fontSize: 10, color: isDark ? Colors.white54 : AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('Visit again',
                    style: TextStyle(fontFamily: 'Geist', fontSize: 9, color: isDark ? Colors.white38 : AppColors.textMuted)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showPrinterSelector(context, settings, orderId, dateStr, timeStr, total, symbol),
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: const Text('Print Receipt', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1F2937),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () { Navigator.pop(context); onDone(); },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
                    ),
                    child: const Text('Done', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPrinterSelector(BuildContext context, SettingsProvider settings,
      String orderId, String dateStr, String timeStr, double total, String symbol) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PrinterSelectorSheet(
        onPrint: (device) async {
          Navigator.pop(ctx);
          _printToDevice(context, settings, device, orderId, dateStr, timeStr, total, symbol);
        },
      ),
    );
  }

  void _printToDevice(BuildContext context, SettingsProvider settings,
      PrinterDevice device, String orderId, String dateStr, String timeStr,
      double total, String symbol) async {
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      const SnackBar(content: Text('Connecting to printer...'), duration: Duration(seconds: 10)),
    );

    final service = PrinterService();
    try {
      await service.connect(device);

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Printing receipt...'), duration: Duration(seconds: 10)),
      );

      await service.printReceipt(
        storeName: settings.storeName,
        storePhone: settings.storePhone,
        storeAddress: settings.storeAddress,
        storeEmail: settings.storeEmail,
        orderId: orderId,
        date: dateStr,
        time: timeStr,
        customerName: customerName,
        customerPhone: customerPhone,
        items: items.map((i) => ReceiptLineItem(
          name: i.productName,
          qty: i.quantity,
          amount: i.price * i.quantity,
        )).toList(),
        total: total.toStringAsFixed(0),
        currencySymbol: symbol,
        totalQty: items.fold(0, (s, i) => s + i.quantity),
      );

      await service.disconnect();

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('✅ Receipt printed to ${device.name}')),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('❌ Print failed: $e')),
      );
    } finally {
      service.dispose();
    }
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontFamily: 'Geist', fontSize: 9, color: isDark ? Colors.white54 : AppColors.textSecondary)),
        Text(value,
            style: TextStyle(fontFamily: 'Geist', fontSize: 9, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
      ],
    );
  }

  Widget _dashedLine(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: 1,
          child: CustomPaint(
            painter: _DashedLinePainter(isDark: isDark),
          ),
        );
      },
    );
  }
}

class _PrinterSelectorSheet extends StatefulWidget {
  final void Function(PrinterDevice device) onPrint;
  const _PrinterSelectorSheet({required this.onPrint});

  @override
  State<_PrinterSelectorSheet> createState() => _PrinterSelectorSheetState();
}

class _PrinterSelectorSheetState extends State<_PrinterSelectorSheet> {
  final PrinterService _service = PrinterService();
  List<PrinterDevice> _printers = [];
  bool _scanning = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    try {
      final printers = await _service.scanPrinters();
      if (mounted) {
        setState(() {
          _printers = printers;
          _scanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _scanning = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(
            color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
            borderRadius: BorderRadius.circular(2),
          )),
          const SizedBox(height: 16),
          Text('Select Printer', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          )),
          const SizedBox(height: 16),
          if (_scanning) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Scanning for printers...', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ] else if (_error != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 40, color: isDark ? Colors.white38 : AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text('Could not find printers', style: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () { setState(() { _scanning = true; _error = null; }); _scan(); },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Scan Again', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ] else if (_printers.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.print_disabled_rounded, size: 40, color: isDark ? Colors.white38 : AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text('No printers found', style: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Turn on Bluetooth or connect to WiFi printer', style: TextStyle(color: isDark ? Colors.white24 : const Color(0xFF9CA3AF), fontSize: 11)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () { setState(() { _scanning = true; }); _scan(); },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Scan Again', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              height: 200,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _printers.length,
                separatorBuilder: (_, _) => Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                itemBuilder: (context, index) {
                  final p = _printers[index];
                  final icon = switch (p.connectionType) {
                    PrinterConnectionType.bluetooth => Icons.bluetooth_rounded,
                    PrinterConnectionType.network => Icons.wifi_rounded,
                    PrinterConnectionType.ble => Icons.bluetooth_connected_rounded,
                    PrinterConnectionType.usb => Icons.usb_rounded,
                  };
                  return ListTile(
                    leading: Icon(icon, color: AppColors.primary),
                    title: Text(p.name, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
                    subtitle: Text(p.connectionType.name, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : AppColors.textMuted)),
                    onTap: () => widget.onPrint(p),
                  );
                },
              ),
            ),
          ],
        ],
      ),
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
