import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';

class PrinterService {
  final PrinterManager _manager = PrinterManager();

  Future<List<PrinterDevice>> scanPrinters() async {
    return _manager.scanPrinters(
      timeout: const Duration(seconds: 5),
      types: {
        PrinterConnectionType.bluetooth,
        PrinterConnectionType.network,
      },
    );
  }

  Future<void> connect(PrinterDevice device) async {
    await _manager.connect(device, timeout: const Duration(seconds: 10));
  }

  Future<void> disconnect() async {
    await _manager.disconnect();
  }

  void dispose() {
    _manager.dispose();
  }

  bool get isConnected => _manager.isConnected;

  Future<void> printReceipt({
    required String storeName,
    required String storePhone,
    required String storeAddress,
    required String storeEmail,
    required String orderId,
    required String date,
    required String time,
    required String customerName,
    required String customerPhone,
    required List<ReceiptLineItem> items,
    required String total,
    required String currencySymbol,
    required int totalQty,
  }) async {
    final ticket = await Ticket.create(PaperSize.mm58);

    ticket.text(storeName,
        style: const PrintTextStyle(bold: true, height: TextSize.size2, width: TextSize.size2),
        align: PrintAlign.center);
    ticket.emptyLines(1);

    if (storePhone.isNotEmpty) {
      ticket.text(storePhone, align: PrintAlign.center);
    }
    if (storeAddress.isNotEmpty) {
      ticket.text(storeAddress, align: PrintAlign.center);
    }
    if (storeEmail.isNotEmpty) {
      ticket.text(storeEmail, align: PrintAlign.center);
    }

    ticket.emptyLines(1);
    ticket.separator();
    ticket.emptyLines(1);

    ticket.text('INVOICE', style: const PrintTextStyle(bold: true), align: PrintAlign.center);
    ticket.emptyLines(1);
    ticket.separator();
    ticket.emptyLines(1);

    ticket.text('Order: $orderId');
    ticket.text('Date: $date');
    ticket.text('Time: $time');
    ticket.text('Customer: $customerName');
    if (customerPhone.isNotEmpty) {
      ticket.text('Phone: $customerPhone');
    }

    ticket.emptyLines(1);
    ticket.separator();
    ticket.emptyLines(1);

    ticket.row([
      PrintColumn(text: 'Item', flex: 3, style: const PrintTextStyle(bold: true)),
      PrintColumn(text: 'Qty', flex: 1, align: PrintAlign.center, style: const PrintTextStyle(bold: true)),
      PrintColumn(text: 'Amount', flex: 2, align: PrintAlign.right, style: const PrintTextStyle(bold: true)),
    ]);

    ticket.separator();

    for (final item in items) {
      ticket.row([
        PrintColumn(text: item.name, flex: 3),
        PrintColumn(text: '${item.qty}', flex: 1, align: PrintAlign.center),
        PrintColumn(text: '$currencySymbol${item.amount.toStringAsFixed(0)}', flex: 2, align: PrintAlign.right),
      ]);
    }

    ticket.separator();
    ticket.emptyLines(1);

    ticket.row([
      PrintColumn(text: 'TOTAL', flex: 4, style: const PrintTextStyle(bold: true, height: TextSize.size2)),
      PrintColumn(text: '$currencySymbol$total', flex: 2, align: PrintAlign.right,
          style: const PrintTextStyle(bold: true, height: TextSize.size2)),
    ]);

    ticket.text('Total Items: $totalQty', align: PrintAlign.right);

    ticket.emptyLines(2);
    ticket.text('Thank you for your purchase!', align: PrintAlign.center);
    ticket.text('Visit again', align: PrintAlign.center);

    ticket.emptyLines(3);
    ticket.cut();

    await _manager.printTicket(ticket);
  }
}

class ReceiptLineItem {
  final String name;
  final int qty;
  final double amount;

  const ReceiptLineItem({
    required this.name,
    required this.qty,
    required this.amount,
  });
}
