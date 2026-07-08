import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/database_helper.dart';
import '../widgets/executive_header.dart';

// ---------------------------------------------------------------------------
// THEME TOKENS
// ---------------------------------------------------------------------------
const _kPrimary = Color(0xFF5A66F9);
const _kBg = Color(0xFFF4F7F6);
const _kCardBg = Colors.white;
const _kRadius = 12.0;

// ---------------------------------------------------------------------------
// REPORT TYPE MODEL
// ---------------------------------------------------------------------------
class _ReportType {
  final String id;
  final String label;
  final IconData icon;
  final String description;
  final List<String> subFilters;
  const _ReportType({required this.id, required this.label, required this.icon, required this.description, required this.subFilters});
}

const _reportTypes = [
  _ReportType(id: 'product',  label: 'Product Report',   icon: Icons.inventory_2_outlined,          description: 'View stock levels, low inventory alerts, and product-wise sales performance.', subFilters: ['Current Stock', 'Low Stock']),
  _ReportType(id: 'customer', label: 'Customer Report',  icon: Icons.people_alt_outlined,           description: 'Generate customer performance, receivable, and recent activity reports from one focused workspace.', subFilters: ['Customer Overview', 'Receivables', 'Activity']),
  _ReportType(id: 'sales',    label: 'Sales Report',     icon: Icons.point_of_sale_outlined,       description: 'Track daily, weekly, and monthly revenue, invoices, and payment methods.', subFilters: ['Invoice Summary', 'Return Summary', 'Collection', 'Outstanding']),
  _ReportType(id: 'supplier', label: 'Supplier Report', icon: Icons.local_shipping_outlined,       description: 'Review purchase orders, supplier payments, and outstanding balances.', subFilters: ['Supplier Overview', 'Payables', 'Purchase Activity']),
  _ReportType(id: 'ledger',   label: 'Ledger Report',    icon: Icons.account_balance_wallet_outlined, description: 'Export the general cash ledger with debit/credit entries and running balance.', subFilters: ['Cash Book', 'Customer Statement', 'Supplier Statement']),
  _ReportType(id: 'expense',  label: 'Expense Report',   icon: Icons.receipt_long_outlined,         description: 'Summarise all recorded expenses by category over a selected date range.', subFilters: ['Expense Overview', 'By Category', 'Cash Outflow']),
];

// ---------------------------------------------------------------------------
// REPORTS SCREEN
// ---------------------------------------------------------------------------
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int? _selectedIndex;
  int _selectedSubFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _selectedRange = 'This Month';
  bool _isGenerating = false;
  Map<String, dynamic>? _reportData;

  DateTimeRange? _getDateRange() {
    final now = DateTime.now();
    switch (_selectedRange) {
      case 'Today':
        return DateTimeRange(start: DateTime(now.year, now.month, now.day), end: now);
      case 'This Week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(start: DateTime(start.year, start.month, start.day), end: now);
      case 'This Month':
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case 'This Year':
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      default:
        return null; // All time
    }
  }

  Future<void> _generateReport(_ReportType report, [int? subFilterOverride]) async {
    final subFilter = subFilterOverride ?? _selectedSubFilterIndex;
    setState(() { _isGenerating = true; _reportData = null; });
    String fmt(DateTime? d) => d?.toIso8601String().substring(0, 10) ?? '1970-01-01';
    try {
      final range = _getDateRange();
      final from = fmt(range?.start);
      final to   = fmt(range?.end ?? DateTime.now());
      Map<String, dynamic> data = {};
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      switch (report.id) {
        case 'sales':
          final rows = await dbHelper.getSalesReportData(fromDate: from, toDate: to);
          double totalRev = 0, outst = 0;
          Map<String, Map<String, dynamic>> methodsMap = {};
          for (var r in rows) {
            totalRev += (r['total'] ?? 0);
            outst += (r['balance'] ?? 0);
            String m = r['payment_method'] ?? 'Unknown';
            methodsMap.putIfAbsent(m, () => {'payment_method': m, 'count': 0, 'total': 0.0});
            methodsMap[m]!['count'] = (methodsMap[m]!['count'] as int) + 1;
            methodsMap[m]!['total'] = (methodsMap[m]!['total'] as double) + ((r['received'] ?? 0) as num).toDouble();
          }
          final returns = await db.rawQuery("SELECT date, invoice_number, 'Return' as customer_name, total_refund as total, 1 as is_return FROM sales_returns WHERE date(date) BETWEEN date(?) AND date(?)", [from, to]);
          data = {
            'rows': [...rows, ...returns],
            'totalRevenue': totalRev,
            'totalSales': rows.length,
            'returnsCount': returns.length,
            'outstanding': outst,
            'methods': methodsMap.values.toList(),
          };
          break;
        case 'product':
          // Always fetch summary counts (for stat cards)
          final allRows = await dbHelper.getProductReportData(fromDate: from, toDate: to);
          int outOfStock = 0;
          for (var r in allRows) { if ((r['stock'] ?? 0) <= 0) outOfStock++; }
          final lowStockRows = await db.rawQuery(
            "SELECT name, category, stock, sell_price, threshold FROM products WHERE stock <= threshold ORDER BY stock ASC");
          // Rows shown in table depend on which sub-filter was selected
          final productRows = subFilter == 1 ? lowStockRows : allRows;
          data = {
            'rows': productRows,
            'allRows': allRows,
            'totalProducts': allRows.length,
            'lowStockCount': lowStockRows.length,
            'outOfStock': outOfStock,
            'lowStockItems': lowStockRows,
            'subFilter': subFilter,
          };
          break;
        case 'customer':
          final rows = await dbHelper.getCustomerReportData(fromDate: from, toDate: to);
          double totPurchases = 0, totOutst = 0;
          for (var r in rows) {
            totPurchases += (r['total_purchases'] ?? 0);
            totOutst += (r['outstanding'] ?? 0);
          }
          final activity = await db.rawQuery("SELECT date, invoice_number as description, total as amount, 'Sale' as type FROM sales WHERE date(date) BETWEEN date(?) AND date(?) ORDER BY date DESC", [from, to]);
          data = {
            'customers': rows,
            'totalPurchases': totPurchases,
            'outstanding': totOutst,
            'activity': activity,
          };
          break;
        case 'supplier':
          final rows = await dbHelper.getSupplierReportData(fromDate: from, toDate: to);
          double pending = 0, advance = 0;
          double orderTotal = 0;
          for (var r in rows) {
            pending += ((r['pendingAmount'] ?? 0) as num).toDouble();
            advance += ((r['advanceAmount'] ?? 0) as num).toDouble();
          }
          final orders = await db.rawQuery("SELECT po_number, supplier, order_date, status, (SELECT COALESCE(SUM(quantity * purchase_price), 0) FROM purchase_order_items WHERE order_id = purchase_orders.id) as order_total, paid_amount FROM purchase_orders WHERE date(order_date) BETWEEN date(?) AND date(?) ORDER BY order_date DESC", [from, to]);
          for (var o in orders) { orderTotal += ((o['order_total'] ?? 0) as num).toDouble(); }
          data = {
            'suppliers': rows,
            'totalPending': pending,
            'totalAdvance': advance,
            'totalSuppliers': rows.length,
            'orderCount': orders.length,
            'orderTotal': orderTotal,
            'orders': orders,
          };
          break;
        case 'expense':
          final rows = await dbHelper.getExpenseReportData(fromDate: from, toDate: to);
          double tot = 0;
          Map<String, Map<String, dynamic>> cats = {};
          for (var r in rows) {
            tot += (r['amount'] ?? 0);
            String c = r['category'] ?? 'Uncategorized';
            cats.putIfAbsent(c, () => {'category': c, 'count': 0, 'total': 0.0});
            cats[c]!['count'] = (cats[c]!['count'] as int) + 1;
            cats[c]!['total'] = (cats[c]!['total'] as double) + ((r['amount'] ?? 0) as num).toDouble();
          }
          data = {
            'expenses': rows,
            'total': tot,
            'count': rows.length,
            'byCategory': cats.values.toList(),
          };
          break;
        case 'ledger':
          final rows = await dbHelper.getGeneralLedger(range?.start, range?.end);
          double inf = 0, outf = 0;
          final mappedRows = rows.map((r) {
            double amt = ((r['debit'] ?? 0) as num).toDouble() - ((r['credit'] ?? 0) as num).toDouble();
            if (amt > 0) { inf += amt; } else { outf += amt.abs(); }
            return {
              'date': r['date'],
              'reference': r['title'],       // query aliases invoice/PO numbers as 'title'
              'description': r['description'], // query aliases party names/notes as 'description'
              'category': r['category'],
              'type': r['type'],
              'amount': amt,
            };
          }).toList();
          data = {
            'entries': mappedRows,
            'inflow': inf,
            'outflow': outf,
            'net': inf - outf,
          };
          break;
        default: data = {};
      }
      setState(() { _reportData = data; });
    } catch (e) {
      debugPrint('Report error: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExecutiveHeader(
              title: 'Reports',
              subtitle: 'Choose a report type, configure filters, then generate a focused on-screen report.',
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 280, child: _buildSidebar()),
                  const SizedBox(width: 24),
                  Expanded(child: _buildPreviewPanel()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SIDEBAR
  // ---------------------------------------------------------------------------
  Widget _buildSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.bar_chart_rounded, color: _kPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Report Builder', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
                    Text('${_reportTypes.length} report types', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text('Choose a report type, configure filters, then generate a focused on-screen report.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500, height: 1.5)),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: List.generate(_reportTypes.length, (i) {
                final report = _reportTypes[i];
                final isSelected = _selectedIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _ReportTypeItem(
                    report: report,
                    isSelected: isSelected,
                    onTap: () => setState(() {
                      _selectedIndex = i;
                      _selectedSubFilterIndex = 0; // reset sub-filter on report-type change
                      _reportData = null;
                    }),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PREVIEW PANEL
  // ---------------------------------------------------------------------------
  Widget _buildPreviewPanel() {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: _selectedIndex == null
          ? _buildEmptyState()
          : _reportData != null
              ? _buildGeneratedReport(_reportTypes[_selectedIndex!], _reportData!, _selectedSubFilterIndex)
              : _buildSelectedState(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.bar_chart_rounded, color: _kPrimary, size: 36),
            ),
            const SizedBox(height: 24),
            const Text('Select report type', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
            const SizedBox(height: 10),
            Text(
              'Choose a report type from the left column to start generating a\nfocused business report on screen.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSelectedState() {
    final report = _reportTypes[_selectedIndex!];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A2E2B))),
                  const SizedBox(height: 8),
                  Text(report.description, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(width: 24),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : () => _generateReport(report, _selectedSubFilterIndex),
              icon: _isGenerating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.flash_on_rounded, size: 20),
              label: Text(_isGenerating ? 'Generating...' : 'Generate Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Sub Filters (Segmented Control equivalent)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(report.subFilters.length, (index) {
              final isSelected = _selectedSubFilterIndex == index;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSubFilterIndex = index;
                      _reportData = null; // Clear data when switching — user must regenerate
                    });
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? _kPrimary.withValues(alpha: 0.1) : Colors.white,
                      border: Border.all(color: isSelected ? _kPrimary : Colors.grey.shade300, width: 1.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      report.subFilters[index],
                      style: TextStyle(
                        color: isSelected ? _kPrimary : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 24),

        // Search and Date Filter
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search ${report.label.toLowerCase()}...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (val) {
                    if (_reportData != null) {
                      // We would trigger a local filter here if needed, 
                      // or just clear data to force re-generation
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: PopupMenuButton<String>(
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) => setState(() { _selectedRange = val; _reportData = null; }),
                itemBuilder: (context) => ['Today', 'Yesterday', 'This Week', 'This Month', 'Last Month', 'This Year']
                    .map((r) => PopupMenuItem(value: r, child: Text(r))).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedRange,
                          style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1A2E2B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Main Report Area
        Expanded(
          child: _reportData == null
            ? _buildPreviewPlaceholder(report.label)
            : _buildGeneratedReport(report, _reportData!, _selectedSubFilterIndex),
        ),
        ],
      ),
    );
  }

  Widget _buildPreviewPlaceholder(String reportLabel) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: const Icon(Icons.description_outlined, size: 36, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text('Generate a $reportLabel snapshot', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B))),
            const SizedBox(height: 8),
            Text(
              'Choose a sub-filter above, then tap Generate Report.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratedReport(_ReportType report, Map<String, dynamic> data, [int subFilter = 0]) {
    final fmt = NumberFormat('#,##0', 'en_US');
    final fmtInt = NumberFormat('#,##0', 'en_US');
    final periodLabel = _selectedRange;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(report.icon, color: _kPrimary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${report.label} · ${report.subFilters[subFilter]}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
                    Text('Period: $periodLabel', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _reportData = null),
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Change Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: BorderSide(color: _kPrimary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _exportPdf(report, data, periodLabel),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: const Text('Export PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Sub-filter tabs (live switching) ─────────────────────────────────
          if (report.subFilters.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(report.subFilters.length, (index) {
                  final isActive = subFilter == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: isActive
                          ? null // already selected
                          : () {
                              if (report.id == 'product') {
                                // Product needs a fresh DB query per sub-filter
                                setState(() {
                                  _selectedSubFilterIndex = index;
                                  _reportData = null;
                                });
                                _generateReport(report, index);
                              } else {
                                // All other reports: data covers every sub-view, just re-render
                                setState(() => _selectedSubFilterIndex = index);
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                        decoration: BoxDecoration(
                          color: isActive ? _kPrimary.withValues(alpha: 0.1) : Colors.white,
                          border: Border.all(
                            color: isActive ? _kPrimary : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          report.subFilters[index],
                          style: TextStyle(
                            color: isActive ? _kPrimary : Colors.grey.shade700,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          const SizedBox(height: 20),

          // Report-specific content dispatched by subFilter
          if (report.id == 'sales')    _buildSalesReport(data, fmt, fmtInt, subFilter)
          else if (report.id == 'product')  _buildProductReport(data, fmt, fmtInt, subFilter)
          else if (report.id == 'customer') _buildCustomerReport(data, fmt, fmtInt, subFilter)
          else if (report.id == 'supplier') _buildSupplierReport(data, fmt, fmtInt, subFilter)
          else if (report.id == 'expense')  _buildExpenseReport(data, fmt, fmtInt, subFilter)
          else if (report.id == 'ledger')   _buildLedgerReport(data, fmt, subFilter),
        ],
      ),
    );
  }

  // ── Sales Report  (0=Invoice Summary  1=Return Summary  2=Collection  3=Outstanding)
  Widget _buildSalesReport(Map<String, dynamic> d, NumberFormat fmt, NumberFormat fmtInt, int sub) {
    final rows    = (d['rows']    as List? ?? []);
    final methods = (d['methods'] as List? ?? []);
    final outstanding = rows.where((r) => (r['balance'] ?? 0) > 0).toList();

    // ---- shared summary cards ----
    final summaryCards = Row(children: [
      _statCard('Revenue',     'Rs. ${fmt.format(d['totalRevenue'] ?? 0)}', Icons.attach_money_rounded, const Color(0xFF0F4C81)),
      const SizedBox(width: 12),
      _statCard('Invoices',    fmtInt.format(d['totalSales'] ?? 0),         Icons.receipt_long_outlined, const Color(0xFF1976D2)),
      const SizedBox(width: 12),
      _statCard('Returns',     fmtInt.format(d['returnsCount'] ?? 0),       Icons.assignment_return_outlined, Colors.orange.shade700),
      const SizedBox(width: 12),
      _statCard('Outstanding', 'Rs. ${fmt.format(d['outstanding'] ?? 0)}',  Icons.pending_actions_outlined, Colors.red.shade700),
    ]);

    switch (sub) {
      // Invoice Summary
      case 0:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          summaryCards, const SizedBox(height: 16),
          _sectionHeader('All Invoices', '${rows.length} records'),
          const SizedBox(height: 8),
          _buildTable(
            headers: ['Date', 'Invoice', 'Customer', 'Payment', 'Total', 'Received', 'Balance'],
            rows: rows.map<List<String>>((r) => [
              _fmtDate(r['date']), r['invoice_number'] ?? '', r['customer_name'] ?? 'Walk-in',
              r['payment_method'] ?? '', 'Rs. ${fmt.format(r['total'] ?? 0)}',
              'Rs. ${fmt.format(r['received'] ?? 0)}', 'Rs. ${fmt.format(r['balance'] ?? 0)}',
            ]).toList(),
            colWidths: const {0: FlexColumnWidth(1.5), 1: FlexColumnWidth(1.5), 2: FlexColumnWidth(2), 3: FlexColumnWidth(1.5), 4: FlexColumnWidth(1.5), 5: FlexColumnWidth(1.5), 6: FlexColumnWidth(1.5)},
          ),
        ]);

      // Return Summary
      case 1:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          summaryCards, const SizedBox(height: 16),
          _sectionHeader('Return Summary', '${d['returnsCount'] ?? 0} returns in period'),
          const SizedBox(height: 8),
          if ((d['returnsCount'] ?? 0) == 0)
            _emptySection('No returns recorded for this period.')
          else
            _buildTable(
              headers: ['Invoice #', 'Customer', 'Date', 'Return Amount'],
              rows: rows.where((r) => (r['is_return'] == 1 || r['is_return'] == true)).map<List<String>>((r) => [
                r['invoice_number'] ?? '', r['customer_name'] ?? 'Walk-in',
                _fmtDate(r['date']), 'Rs. ${fmt.format(r['total'] ?? 0)}',
              ]).toList(),
              colWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(2.5), 2: FlexColumnWidth(2), 3: FlexColumnWidth(2)},
            ),
        ]);

      // Collection (Payment Methods)
      case 2:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          summaryCards, const SizedBox(height: 16),
          _sectionHeader('Collection by Method', '${methods.length} methods'),
          const SizedBox(height: 8),
          if (methods.isEmpty)
            _emptySection('No collection data for this period.')
          else ...[
            Row(children: methods.map<Widget>((m) {
              return Expanded(child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m['payment_method'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
                    const SizedBox(height: 4),
                    Text('${m['count'] ?? 0} invoices', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(height: 6),
                    Text('Rs. ${fmt.format(m['total'] ?? 0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _kPrimary)),
                  ]),
                ),
              ));
            }).toList()),
            const SizedBox(height: 16),
            _buildTable(
              headers: ['Date', 'Invoice', 'Customer', 'Method', 'Amount'],
              rows: rows.map<List<String>>((r) => [
                _fmtDate(r['date']), r['invoice_number'] ?? '', r['customer_name'] ?? 'Walk-in',
                r['payment_method'] ?? '', 'Rs. ${fmt.format(r['received'] ?? 0)}',
              ]).toList(),
              colWidths: const {0: FlexColumnWidth(1.5), 1: FlexColumnWidth(1.5), 2: FlexColumnWidth(2), 3: FlexColumnWidth(1.5), 4: FlexColumnWidth(2)},
            ),
          ],
        ]);

      // Outstanding
      default:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          summaryCards, const SizedBox(height: 16),
          _sectionHeader('Outstanding Invoices', '${outstanding.length} unpaid / partial'),
          const SizedBox(height: 8),
          if (outstanding.isEmpty)
            _emptySection('No outstanding balances — all invoices are fully paid!')
          else
            _buildTable(
              headers: ['Date', 'Invoice', 'Customer', 'Total', 'Received', 'Balance'],
              rows: outstanding.map<List<String>>((r) => [
                _fmtDate(r['date']), r['invoice_number'] ?? '', r['customer_name'] ?? 'Walk-in',
                'Rs. ${fmt.format(r['total'] ?? 0)}', 'Rs. ${fmt.format(r['received'] ?? 0)}',
                'Rs. ${fmt.format(r['balance'] ?? 0)}',
              ]).toList(),
              colWidths: const {0: FlexColumnWidth(1.5), 1: FlexColumnWidth(1.5), 2: FlexColumnWidth(2), 3: FlexColumnWidth(1.5), 4: FlexColumnWidth(1.5), 5: FlexColumnWidth(1.5)},
            ),
        ]);
    }
  }

  // ── Product Report  (0=Current Stock  1=Low Stock)
  Widget _buildProductReport(Map<String, dynamic> d, NumberFormat fmt, NumberFormat fmtInt, int sub) {
    final reportedSub = (d['subFilter'] as int?) ?? sub; // use the sub-filter that was used to generate
    final displayRows = (d['rows'] as List? ?? []);

    final summaryCards = Row(children: [
      _statCard('Total Products', fmtInt.format(d['totalProducts'] ?? 0), Icons.inventory_2_outlined, const Color(0xFF0F4C81)),
      const SizedBox(width: 12),
      _statCard('Low Stock',      fmtInt.format(d['lowStockCount'] ?? 0), Icons.warning_amber_outlined, Colors.orange.shade700),
      const SizedBox(width: 12),
      _statCard('Out of Stock',   fmtInt.format(d['outOfStock'] ?? 0),    Icons.remove_shopping_cart_outlined, Colors.red.shade700),
    ]);

    if (reportedSub == 1) {
      // Low Stock — only items at or below their reorder threshold
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        summaryCards, const SizedBox(height: 16),
        _sectionHeader('Low Stock Items', '${displayRows.length} items at or below threshold'),
        const SizedBox(height: 8),
        displayRows.isEmpty
          ? _emptySection('Great news — no products are below their reorder threshold!')
          : _buildTable(
              headers: ['Product', 'Category', 'Current Stock', 'Threshold', 'Sell Price'],
              rows: displayRows.map<List<String>>((p) => [
                p['name'] ?? '', p['category'] ?? '',
                (p['stock'] ?? 0).toString(),
                (p['threshold'] ?? 0).toString(),
                'Rs. ${fmt.format(p['sell_price'] ?? 0)}',
              ]).toList(),
              colWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1.5), 3: FlexColumnWidth(1.5), 4: FlexColumnWidth(2)},
            ),
      ]);
    }

    // Current Stock (sub == 0) — ALL products with their stock levels
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      summaryCards, const SizedBox(height: 16),
      _sectionHeader('Current Stock', '${displayRows.length} products'),
      const SizedBox(height: 8),
      displayRows.isEmpty
        ? _emptySection('No product data found.')
        : _buildTable(
            headers: ['Product', 'Category', 'Stock', 'Sell Price', 'Cost Price'],
            rows: displayRows.map<List<String>>((p) => [
              p['name'] ?? p['product_name'] ?? '', p['category'] ?? '',
              (p['stock'] ?? p['qty_sold'] ?? 0).toString(),
              'Rs. ${fmt.format(p['sell_price'] ?? 0)}',
              'Rs. ${fmt.format(p['cost_price'] ?? p['revenue'] ?? 0)}',
            ]).toList(),
            colWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1.5), 3: FlexColumnWidth(2), 4: FlexColumnWidth(2)},
          ),
    ]);
  }

  // ── Customer Report  (0=Overview  1=Receivables  2=Activity)
  Widget _buildCustomerReport(Map<String, dynamic> d, NumberFormat fmt, NumberFormat fmtInt, int sub) {
    final customers        = (d['customers']        as List? ?? []);
    final salesPerCustomer = (d['salesPerCustomer'] as List? ?? []);
    final receivables      = customers.where((c) => (c['pendingAmount'] ?? 0) > 0).toList();

    final summaryCards = Row(children: [
      _statCard('Total Customers', fmtInt.format(d['totalCustomers'] ?? 0), Icons.people_alt_outlined, const Color(0xFF0F4C81)),
      const SizedBox(width: 12),
      _statCard('Total Pending',   'Rs. ${fmt.format(d['totalPending'] ?? 0)}', Icons.pending_actions_outlined, Colors.red.shade700),
      const SizedBox(width: 12),
      _statCard('Advance Credit',  'Rs. ${fmt.format(d['totalAdvance'] ?? 0)}', Icons.account_balance_wallet_outlined, Colors.green.shade700),
    ]);

    switch (sub) {
      case 1: // Receivables
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          summaryCards, const SizedBox(height: 16),
          _sectionHeader('Receivables', '${receivables.length} customers with pending balance'),
          const SizedBox(height: 8),
          receivables.isEmpty
            ? _emptySection('No outstanding receivables found.')
            : _buildTable(
                headers: ['Customer', 'Phone', 'Pending Balance', 'Advance'],
                rows: receivables.map<List<String>>((c) => [
                  c['name'] ?? '', c['phone'] ?? '',
                  'Rs. ${fmt.format(c['pendingAmount'] ?? 0)}',
                  'Rs. ${fmt.format(c['advanceAmount'] ?? 0)}',
                ]).toList(),
                colWidths: const {0: FlexColumnWidth(2.5), 1: FlexColumnWidth(2), 2: FlexColumnWidth(2), 3: FlexColumnWidth(2)},
              ),
        ]);

      case 2: // Activity
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          summaryCards, const SizedBox(height: 16),
          _sectionHeader('Customer Activity', 'Sales in period: ${salesPerCustomer.length} active customers'),
          const SizedBox(height: 8),
          salesPerCustomer.isEmpty
            ? _emptySection('No customer activity recorded for this period.')
            : _buildTable(
                headers: ['Customer', 'Invoices', 'Total Purchases'],
                rows: salesPerCustomer.map<List<String>>((c) => [
                  c['customer_name'] ?? 'Walk-in',
                  (c['count'] ?? 0).toString(),
                  'Rs. ${fmt.format(c['total'] ?? 0)}',
                ]).toList(),
                colWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(2), 2: FlexColumnWidth(2.5)},
              ),
        ]);

      default: // Overview
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          summaryCards, const SizedBox(height: 16),
          _sectionHeader('All Customers', '${customers.length} records'),
          const SizedBox(height: 8),
          customers.isEmpty
            ? _emptySection('No customer data found.')
            : _buildTable(
                headers: ['Name', 'Phone', 'Total Purchases', 'Pending', 'Advance'],
                rows: customers.take(50).map<List<String>>((c) => [
                  c['name'] ?? '', c['phone'] ?? '',
                  'Rs. ${fmt.format(c['totalPurchases'] ?? 0)}',
                  'Rs. ${fmt.format(c['pendingAmount'] ?? 0)}',
                  'Rs. ${fmt.format(c['advanceAmount'] ?? 0)}',
                ]).toList(),
                colWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(2), 2: FlexColumnWidth(2), 3: FlexColumnWidth(2), 4: FlexColumnWidth(2)},
              ),
        ]);
    }
  }

  // ── Supplier Report  (0=Overview  1=Payables  2=Purchase Activity)
  Widget _buildSupplierReport(Map<String, dynamic> d, NumberFormat fmt, NumberFormat fmtInt, int sub) {
    final orders    = (d['orders']    as List? ?? []);
    final suppliers = (d['suppliers'] as List? ?? []);
    final payables  = suppliers.where((s) => (s['pendingAmount'] ?? 0) > 0).toList();

    final summaryCards = Row(children: [
      _statCard('Total Suppliers', fmtInt.format(d['totalSuppliers'] ?? 0), Icons.local_shipping_outlined, const Color(0xFF0F4C81)),
      const SizedBox(width: 12),
      _statCard('PO Count',        fmtInt.format(d['orderCount'] ?? 0),     Icons.shopping_cart_outlined, const Color(0xFF1976D2)),
      const SizedBox(width: 12),
      _statCard('PO Total',        'Rs. ${fmt.format(d['orderTotal'] ?? 0)}', Icons.attach_money_rounded, Colors.green.shade700),
      const SizedBox(width: 12),
      _statCard('Outstanding',     'Rs. ${fmt.format(d['totalPending'] ?? 0)}', Icons.pending_actions_outlined, Colors.red.shade700),
    ]);

    switch (sub) {
      case 1: // Payables
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          summaryCards, const SizedBox(height: 16),
          _sectionHeader('Payables', '${payables.length} suppliers with outstanding balance'),
          const SizedBox(height: 8),
          payables.isEmpty
            ? _emptySection('No payables found — all supplier balances are cleared!')
            : _buildTable(
                headers: ['Company', 'Contact', 'Phone', 'Pending', 'Advance'],
                rows: payables.map<List<String>>((s) => [
                  s['companyName'] ?? '', s['contactPerson'] ?? '', s['phone'] ?? '',
                  'Rs. ${fmt.format(s['pendingAmount'] ?? 0)}',
                  'Rs. ${fmt.format(s['advanceAmount'] ?? 0)}',
                ]).toList(),
                colWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1.5), 3: FlexColumnWidth(2), 4: FlexColumnWidth(2)},
              ),
        ]);

      case 2: // Purchase Activity
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          summaryCards, const SizedBox(height: 16),
          _sectionHeader('Purchase Orders', '${orders.length} orders in period'),
          const SizedBox(height: 8),
          orders.isEmpty
            ? _emptySection('No purchase orders found for this period.')
            : _buildTable(
                headers: ['PO Number', 'Supplier', 'Date', 'Status', 'PO Total', 'Paid'],
                rows: orders.map<List<String>>((o) => [
                  o['po_number'] ?? '', o['supplier'] ?? '',
                  _fmtDate(o['order_date']), o['status'] ?? '',
                  'Rs. ${fmt.format(o['order_total'] ?? 0)}',
                  'Rs. ${fmt.format(o['paid_amount'] ?? 0)}',
                ]).toList(),
                colWidths: const {0: FlexColumnWidth(1.5), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1.5), 3: FlexColumnWidth(1.2), 4: FlexColumnWidth(1.5), 5: FlexColumnWidth(1.5)},
              ),
        ]);

      default: // Overview
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          summaryCards, const SizedBox(height: 16),
          _sectionHeader('All Suppliers', '${suppliers.length} records'),
          const SizedBox(height: 8),
          suppliers.isEmpty
            ? _emptySection('No supplier data found.')
            : _buildTable(
                headers: ['Company', 'Contact', 'Phone', 'Pending', 'Advance'],
                rows: suppliers.map<List<String>>((s) => [
                  s['companyName'] ?? '', s['contactPerson'] ?? '', s['phone'] ?? '',
                  'Rs. ${fmt.format(s['pendingAmount'] ?? 0)}',
                  'Rs. ${fmt.format(s['advanceAmount'] ?? 0)}',
                ]).toList(),
                colWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1.5), 3: FlexColumnWidth(2), 4: FlexColumnWidth(2)},
              ),
        ]);
    }
  }

  // ── Expense Report  (0=Overview  1=By Category  2=Cash Outflow)
  Widget _buildExpenseReport(Map<String, dynamic> d, NumberFormat fmt, NumberFormat fmtInt, int sub) {
    final expenses   = (d['expenses']   as List? ?? []);
    final byCategory = (d['byCategory'] as List? ?? []);
    final cashOut    = expenses.where((e) => (e['amount'] ?? 0) > 0).toList();

    final summaryCards = Row(children: [
      _statCard('Total Expenses', 'Rs. ${fmt.format(d['total'] ?? 0)}', Icons.receipt_long_outlined, const Color(0xFF0F4C81)),
      const SizedBox(width: 12),
      _statCard('Count',      fmtInt.format(d['count'] ?? 0),       Icons.numbers_outlined, const Color(0xFF1976D2)),
      const SizedBox(width: 12),
      _statCard('Categories', fmtInt.format(byCategory.length), Icons.category_outlined, Colors.orange.shade700),
    ]);

    switch (sub) {
      case 1: // By Category
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          summaryCards, const SizedBox(height: 16),
          _sectionHeader('Expenses by Category', '${byCategory.length} categories'),
          const SizedBox(height: 8),
          byCategory.isEmpty
            ? _emptySection('No expense categories found for this period.')
            : _buildTable(
                headers: ['Category', 'Count', 'Total'],
                rows: byCategory.map<List<String>>((c) => [
                  c['category'] ?? '',
                  (c['count'] ?? 0).toString(),
                  'Rs. ${fmt.format(c['total'] ?? 0)}',
                ]).toList(),
                colWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1.5), 2: FlexColumnWidth(2)},
              ),
        ]);

      case 2: // Cash Outflow
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          summaryCards, const SizedBox(height: 16),
          _sectionHeader('Cash Outflow', '${cashOut.length} outflow transactions'),
          const SizedBox(height: 8),
          cashOut.isEmpty
            ? _emptySection('No cash outflow records found for this period.')
            : _buildTable(
                headers: ['Date', 'Category', 'Title', 'Amount'],
                rows: cashOut.map<List<String>>((e) => [
                  _fmtDate(e['date']), e['category'] ?? '', e['title'] ?? '',
                  'Rs. ${fmt.format(e['amount'] ?? 0)}',
                ]).toList(),
                colWidths: const {0: FlexColumnWidth(1.5), 1: FlexColumnWidth(2), 2: FlexColumnWidth(3), 3: FlexColumnWidth(2)},
              ),
        ]);

      default: // Overview
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          summaryCards, const SizedBox(height: 16),
          _sectionHeader('All Expenses', '${expenses.length} records'),
          const SizedBox(height: 8),
          expenses.isEmpty
            ? _emptySection('No expenses recorded for this period.')
            : _buildTable(
                headers: ['Date', 'Category', 'Title', 'Amount', 'Notes'],
                rows: expenses.map<List<String>>((e) => [
                  _fmtDate(e['date']), e['category'] ?? '', e['title'] ?? '',
                  'Rs. ${fmt.format(e['amount'] ?? 0)}', e['notes'] ?? '',
                ]).toList(),
                colWidths: const {0: FlexColumnWidth(1.5), 1: FlexColumnWidth(1.5), 2: FlexColumnWidth(2.5), 3: FlexColumnWidth(1.5), 4: FlexColumnWidth(2)},
              ),
        ]);
    }
  }

  // ── Ledger Report  (0=Cash Book  1=Customer Statement  2=Supplier Statement)
  Widget _buildLedgerReport(Map<String, dynamic> d, NumberFormat fmt, int sub) {
    final entries      = (d['entries'] as List? ?? []).cast<Map<String, dynamic>>();
    final custEntries  = entries.where((e) => ['Sales', 'Open Return', 'Sales Return', 'Customer Receipt'].contains(e['category'])).toList();
    final suppEntries  = entries.where((e) => ['Purchase', 'Supplier Payment'].contains(e['category'])).toList();

    List<Map<String, dynamic>> displayEntries;
    String sectionTitle;
    switch (sub) {
      case 1:
        displayEntries = custEntries;
        sectionTitle = 'Customer Statement';
        break;
      case 2:
        displayEntries = suppEntries;
        sectionTitle = 'Supplier Statement';
        break;
      default:
        displayEntries = entries;
        sectionTitle = 'Cash Book';
    }

    double inf = 0;
    double outf = 0;
    for (var r in displayEntries) {
      double amt = ((r['debit'] ?? 0) as num).toDouble() - ((r['credit'] ?? 0) as num).toDouble();
      if (amt > 0) { inf += amt; } else { outf += amt.abs(); }
    }
    double net = inf - outf;

    final summaryCards = Row(children: [
      _statCard('Total Inflow',  'Rs. ${fmt.format(inf)}',  Icons.call_received, Colors.green.shade700),
      const SizedBox(width: 12),
      _statCard('Total Outflow', 'Rs. ${fmt.format(outf)}', Icons.call_made, Colors.red.shade700),
      const SizedBox(width: 12),
      _statCard('Net Balance',   'Rs. ${fmt.format(net)}',     Icons.account_balance_wallet_outlined, const Color(0xFF0F4C81)),
    ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      summaryCards, const SizedBox(height: 16),
      _sectionHeader(sectionTitle, '${displayEntries.length} entries'),
      const SizedBox(height: 8),
      displayEntries.isEmpty
        ? _emptySection('No entries found for this view.')
        : _buildTable(
            headers: ['Date', 'Reference', 'Description', 'Category', 'Type', 'Amount'],
            rows: displayEntries.map<List<String>>((e) => [
              _fmtDate(e['date']), e['reference'] ?? '',
              e['description'] ?? '', e['category'] ?? '',
              e['type'] ?? '',
              'Rs. ${fmt.format(((e['amount'] ?? 0) as num).abs())}',
            ]).toList(),
            colWidths: const {0: FlexColumnWidth(1.5), 1: FlexColumnWidth(1.5), 2: FlexColumnWidth(2), 3: FlexColumnWidth(1.5), 4: FlexColumnWidth(1.2), 5: FlexColumnWidth(1.5)},
          ),
    ]);
  }


  // ---------------------------------------------------------------------------
  // SHARED WIDGETS
  // ---------------------------------------------------------------------------
  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _emptySection(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_outlined, size: 36, color: Colors.grey.shade400),
        const SizedBox(height: 10),
        Text(message, style: TextStyle(fontSize: 13, color: Colors.grey.shade500), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _sectionHeader(String title, String sub) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
        if (sub.isNotEmpty) ...[
          const Spacer(),
          Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ],
    );
  }

  Widget _buildTable({
    required List<String> headers,
    required List<List<String>> rows,
    required Map<int, TableColumnWidth> colWidths,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: Colors.grey.shade50,
              child: Table(
                columnWidths: colWidths,
                children: [
                  TableRow(
                    children: headers.map((h) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(h, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600, letterSpacing: 0.3)),
                    )).toList(),
                  ),
                ],
              ),
            ),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No data available', style: TextStyle(fontSize: 13, color: Colors.grey.shade400))),
              )
            else
              Table(
                columnWidths: colWidths,
                children: rows.asMap().entries.map((entry) {
                  final i = entry.key;
                  final row = entry.value;
                  return TableRow(
                    decoration: BoxDecoration(
                      color: i.isEven ? Colors.white : Colors.grey.shade50,
                      border: Border(top: BorderSide(color: Colors.grey.shade100)),
                    ),
                    children: row.map((cell) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Text(cell, style: const TextStyle(fontSize: 12.5, color: Color(0xFF1A2E2B))),
                    )).toList(),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(dynamic val) {
    if (val == null) return '';
    try { return DateFormat('dd MMM yyyy').format(DateTime.parse(val.toString())); } catch (_) { return val.toString(); }
  }

  // ---------------------------------------------------------------------------
  // PDF EXPORT
  // ---------------------------------------------------------------------------
  Future<void> _exportPdf(_ReportType report, Map<String, dynamic> data, String period) async {
    final settings = await DatabaseHelper.instance.getAllSettings();
    final shopName = settings['shop_name'] ?? 'Pharmacy';
    final pdf = pw.Document();
    final fmt = NumberFormat('#,##0.00', 'en_US');

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(report.label, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text('Period: $period', style: const pw.TextStyle(fontSize: 10)),
          ]),
          pw.Text(shopName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ]),
        pw.Divider(),
        pw.SizedBox(height: 8),
        ..._buildPdfContent(report, data, fmt),
      ],
    ));

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  List<pw.Widget> _buildPdfContent(_ReportType report, Map<String, dynamic> data, NumberFormat fmt) {
    switch (report.id) {
      case 'sales':
        final rows = data['rows'] as List? ?? [];
        return [
          pw.Row(children: [
            _pdfStat('Revenue', 'Rs. '),
            _pdfStat('Invoices', (data['totalSales'] ?? 0).toString()),
            _pdfStat('Outstanding', 'Rs. '),
          ]),
          pw.SizedBox(height: 12),
          pw.Text('Transactions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 6),
          pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), children: [
            pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey200), children: [
              for (final h in ['Date', 'Invoice', 'Customer', 'Total', 'Received', 'Balance'])
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
            ]),
            for (final r in rows)
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_fmtDate(r['date']), style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(r['invoice_number'] ?? '', style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(r['customer_name'] ?? 'Walk-in', style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Rs. ', style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Rs. ', style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Rs. ', style: const pw.TextStyle(fontSize: 8))),
              ]),
          ]),
        ];

      case 'expense':
        final expenses = data['expenses'] as List? ?? [];
        final byCategory = data['byCategory'] as List? ?? [];
        return [
          pw.Row(children: [
            _pdfStat('Total', 'Rs. '),
            _pdfStat('Count', (data['count'] ?? 0).toString()),
          ]),
          pw.SizedBox(height: 12),
          pw.Text('By Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 6),
          pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), children: [
            pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey200), children: [
              for (final h in ['Category', 'Count', 'Total'])
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
            ]),
            for (final c in byCategory)
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(c['category'] ?? '', style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text((c['count'] ?? 0).toString(), style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Rs. ', style: const pw.TextStyle(fontSize: 8))),
              ]),
          ]),
          pw.SizedBox(height: 12),
          pw.Text('Expense Entries', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 6),
          pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), children: [
            pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey200), children: [
              for (final h in ['Date', 'Category', 'Title', 'Amount'])
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
            ]),
            for (final e in expenses)
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_fmtDate(e['date']), style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(e['category'] ?? '', style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(e['title'] ?? '', style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Rs. ', style: const pw.TextStyle(fontSize: 8))),
              ]),
          ]),
        ];

      case 'ledger':
        final entries = data['entries'] as List? ?? [];
        double inf = 0.0;
        double outf = 0.0;
        for (final e in entries) {
          if ((e['amount'] as num? ?? 0) > 0) {
            inf += (e['amount'] as num? ?? 0);
          } else {
            outf += (e['amount'] as num? ?? 0).abs();
          }
        }
        final _ = inf - outf; // net — kept for potential future PDF use
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

      default:
        return [pw.Text('Report data available. Please use on-screen view for details.', style: const pw.TextStyle(fontSize: 11))];
    }
  }
  pw.Widget _pdfStat(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 8),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(4)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// REPORT TYPE ITEM (sidebar row)
// ---------------------------------------------------------------------------
class _ReportTypeItem extends StatefulWidget {
  final _ReportType report;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReportTypeItem({required this.report, required this.isSelected, required this.onTap});

  @override
  State<_ReportTypeItem> createState() => _ReportTypeItemState();
}

class _ReportTypeItemState extends State<_ReportTypeItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _kPrimary.withValues(alpha: 0.08) : _hovered ? Colors.grey.shade50 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? _kPrimary.withValues(alpha: 0.3) : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(widget.report.icon, size: 18, color: selected ? _kPrimary : Colors.grey.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.report.label,
                  style: TextStyle(fontSize: 13.5, fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? _kPrimary : const Color(0xFF1A2E2B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected) const Icon(Icons.chevron_right_rounded, size: 16, color: _kPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DATE FILTER CHIP
// ---------------------------------------------------------------------------
class _DateFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateFilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  State<_DateFilterChip> createState() => _DateFilterChipState();
}

class _DateFilterChipState extends State<_DateFilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected ? _kPrimary : _hovered ? Colors.grey.shade100 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.isSelected ? _kPrimary : Colors.grey.shade200),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: widget.isSelected ? Colors.white : Colors.grey.shade700),
            ),
          ),
        ),
      ),
    );
  }
}




