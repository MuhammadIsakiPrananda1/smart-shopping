import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../features/shopping_list/domain/entities.dart';

class ExportService {
  static Future<String> exportToCSV(List<ShoppingItem> items, String listName) async {
    List<List<dynamic>> rows = [];
    rows.add(["Nama Barang", "Kategori", "Status", "Jumlah", "Ditambahkan Pada"]);

    for (var item in items) {
      rows.add([
        item.name,
        item.category,
        item.isChecked ? "Selesai" : "Belum",
        item.quantity ?? 1,
        item.addedAt.toIso8601String(),
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/export_$listName.csv";
    final file = File(path);
    await file.writeAsString(csvData);
    return path;
  }

  static Future<String> exportToPDF(List<ShoppingItem> items, String listName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Daftar Belanja: $listName", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ["Nama", "Kat", "Status"],
                data: items.map<List<String>>((i) => [i.name, i.category, i.isChecked ? "V" : "X"]).toList(),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/export_$listName.pdf";
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }

  static Future<String> exportHistoryToPDF(List<Map> history, String currency) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(2.0 * PdfPageFormat.cm),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Laporan Riwayat Belanja", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ["Nama Barang", "Kategori", "Harga", "Tanggal"],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellAlignment: pw.Alignment.centerLeft,
              data: history.map((item) {
                final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                final date = DateTime.parse(item['purchasedAt'] as String);
                return [
                  item['itemName'] ?? '-',
                  item['category'] ?? '-',
                  "$currency ${price.toStringAsFixed(0)}",
                  "${date.day}/${date.month}/${date.year}",
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Text("Total Transaksi: ${history.length}"),
          ];
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/riwayat_belanja_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }
}
