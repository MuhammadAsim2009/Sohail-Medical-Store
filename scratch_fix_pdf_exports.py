import re
import os

file_path = r"d:\pharmacy\lib\screens\reports_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

replacement = '''      case 'ledger':
        final entries = data['entries'] as List? ?? [];
        return [
          pw.Row(children: [
            _pdfStat('Inflow', 'Rs. '),
            _pdfStat('Outflow', 'Rs. '),
            _pdfStat('Net', 'Rs. '),
          ]),
          pw.SizedBox(height: 12),
          pw.Text('Ledger Entries', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 6),
          pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), children: [
            pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey200), children: [
              for (final h in ['Date', 'Ref', 'Description', 'Category', 'Amount'])
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
            ]),
            for (final e in entries)
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_fmtDate(e['date']), style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(e['reference'] ?? '', style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(e['description'] ?? '', style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(e['category'] ?? '', style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Rs. ', style: const pw.TextStyle(fontSize: 8))),
              ]),
          ]),
        ];

      case 'product':
        final rows = data['rows'] as List? ?? [];
        return [
          pw.Row(children: [
            _pdfStat('Products', (data['totalProducts'] ?? 0).toString()),
            _pdfStat('Low Stock', (data['lowStockCount'] ?? 0).toString()),
            _pdfStat('Out of Stock', (data['outOfStock'] ?? 0).toString()),
          ]),
          pw.SizedBox(height: 12),
          pw.Text('Inventory Report', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 6),
          pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), children: [
            pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey200), children: [
              for (final h in ['Product', 'Category', 'Stock', 'Price'])
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
            ]),
            for (final r in rows)
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(r['name'] ?? '', style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(r['category'] ?? '', style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text((r['stock'] ?? 0).toString(), style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Rs. ', style: const pw.TextStyle(fontSize: 8))),
              ]),
          ]),
        ];

      case 'customer':
        final customers = data['customers'] as List? ?? [];
        return [
          pw.Row(children: [
            _pdfStat('Purchases', 'Rs. '),
            _pdfStat('Outstanding', 'Rs. '),
          ]),
          pw.SizedBox(height: 12),
          pw.Text('Customer Balances', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 6),
          pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), children: [
            pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey200), children: [
              for (final h in ['Name', 'Phone', 'Total', 'Pending'])
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
            ]),
            for (final c in customers)
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(c['name'] ?? '', style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(c['phone'] ?? '', style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Rs. ', style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Rs. ', style: const pw.TextStyle(fontSize: 8))),
              ]),
          ]),
        ];

      case 'supplier':
        final suppliers = data['suppliers'] as List? ?? [];
        return [
          pw.Row(children: [
            _pdfStat('Pending', 'Rs. '),
            _pdfStat('Advance', 'Rs. '),
          ]),
          pw.SizedBox(height: 12),
          pw.Text('Supplier Balances', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 6),
          pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), children: [
            pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey200), children: [
              for (final h in ['Company', 'Contact', 'Pending', 'Advance'])
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
            ]),
            for (final s in suppliers)
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(s['company_name'] ?? '', style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(s['contact_person'] ?? '', style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Rs. ', style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Rs. ', style: const pw.TextStyle(fontSize: 8))),
              ]),
          ]),
        ];

      default:'''

target = "      default:\n        return [pw.Text('Report data available. Please use on-screen view for details.', style: const pw.TextStyle(fontSize: 11))];"
if target in content:
    content = content.replace(target, replacement + "\n        return [pw.Text('Report data available. Please use on-screen view for details.', style: const pw.TextStyle(fontSize: 11))];")
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Success")
else:
    print("Target not found")
