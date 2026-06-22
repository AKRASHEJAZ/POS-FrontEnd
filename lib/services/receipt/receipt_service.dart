import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:web_end/models/sale_view_model.dart';

class ReceiptService {
  static Future<void> printReceipt({
    required SaleModel sale,
    bool is80mm = true,
  }) async {
    final doc = pw.Document();

    final double width = (is80mm ? 80 : 58) * PdfPageFormat.mm;
    
    // Define format with wrap-content style or custom page
    final format = PdfPageFormat(
      width,
      double.infinity,
      marginLeft: 4 * PdfPageFormat.mm,
      marginRight: 4 * PdfPageFormat.mm,
      marginTop: 6 * PdfPageFormat.mm,
      marginBottom: 6 * PdfPageFormat.mm,
    );

    final font = await PdfGoogleFonts.courierPrimeRegular();
    final fontBold = await PdfGoogleFonts.courierPrimeBold();

    final textStyle = pw.TextStyle(font: font, fontSize: 8.5);
    final boldStyle = pw.TextStyle(font: fontBold, fontSize: 9);
    final headerStyle = pw.TextStyle(font: fontBold, fontSize: 12);

    final customerName = sale.customer?.name ?? 'Walk-in Customer';
    final dateStr = sale.saleDate != null
        ? '${sale.saleDate!.year}-${sale.saleDate!.month.toString().padLeft(2, '0')}-${sale.saleDate!.day.toString().padLeft(2, '0')} ${sale.saleDate!.hour.toString().padLeft(2, '0')}:${sale.saleDate!.minute.toString().padLeft(2, '0')}'
        : '—';

    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          final computedTotal = sale.actions.isEmpty
              ? sale.totalAmount
              : sale.actions.fold<double>(0, (sum, a) => sum + a.lineTotal);

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header / Store Info
              pw.Center(
                child: pw.Text('SMART POS', style: headerStyle),
              ),
              pw.Center(
                child: pw.Text('Terminal Receipt', style: boldStyle),
              ),
              pw.SizedBox(height: 4),
              pw.Text('------------------------------------------', style: textStyle),
              
              // Metadata
              pw.Text('Sale ID: #${sale.id}', style: boldStyle),
              pw.Text('Date: $dateStr', style: textStyle),
              pw.Text('Customer: $customerName', style: textStyle),
              if (sale.createdBy?.name != null)
                pw.Text('Cashier: ${sale.createdBy!.name}', style: textStyle),
              pw.Text('------------------------------------------', style: textStyle),

              // Items Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Item Description', style: boldStyle),
                  pw.Text('Total', style: boldStyle),
                ],
              ),
              pw.Text('------------------------------------------', style: textStyle),

              // Line Items
              ...sale.actions.map((action) {
                final batch = action.inventoryBatch;
                final product = batch?.product;
                final productName = product?.name ?? 'Product #${action.inventoryBatchId}';
                final qty = action.quantity;
                final price = batch?.sellingPrice ?? 0.0;
                final lineTotal = action.lineTotal;

                final unit = product?.unitSymbol != null && product!.unitSymbol!.isNotEmpty
                    ? ' ${product.unitSymbol}'
                    : '';

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(productName, style: boldStyle),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('  ${qty.toStringAsFixed(0)}$unit x ${price.toStringAsFixed(2)}', style: textStyle),
                          pw.Text(lineTotal.toStringAsFixed(2), style: textStyle),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              pw.Text('------------------------------------------', style: textStyle),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL AMOUNT:', style: boldStyle),
                  pw.Text(computedTotal.toStringAsFixed(2), style: boldStyle),
                ],
              ),

              pw.Text('------------------------------------------', style: textStyle),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text('THANK YOU FOR YOUR VISIT', style: boldStyle),
              ),
              pw.Center(
                child: pw.Text('Please keep your receipt', style: textStyle),
              ),
            ],
          );
        },
      ),
    );

    // Prompt browser/device print dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'receipt_sale_${sale.id}.pdf',
      format: format,
    );
  }
}
