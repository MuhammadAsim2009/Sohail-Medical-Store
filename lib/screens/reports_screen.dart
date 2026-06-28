import 'package:flutter/material.dart';
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
  final String label;
  final IconData icon;
  final String description;
  const _ReportType({required this.label, required this.icon, required this.description});
}

const _reportTypes = [
  _ReportType(
    label: 'Product Report',
    icon: Icons.inventory_2_outlined,
    description: 'View stock levels, low inventory alerts, and product-wise sales performance.',
  ),
  _ReportType(
    label: 'Customer Report',
    icon: Icons.people_alt_outlined,
    description: 'Analyse customer purchase history, outstanding balances, and loyalty trends.',
  ),
  _ReportType(
    label: 'Sales Report',
    icon: Icons.point_of_sale_outlined,
    description: 'Track daily, weekly, and monthly revenue, invoices, and payment methods.',
  ),
  _ReportType(
    label: 'Suppliers Report',
    icon: Icons.local_shipping_outlined,
    description: 'Review purchase orders, supplier payments, and outstanding balances.',
  ),
  _ReportType(
    label: 'Ledger Report',
    icon: Icons.account_balance_wallet_outlined,
    description: 'Export the general cash ledger with debit/credit entries and running balance.',
  ),
  _ReportType(
    label: 'Expense Report',
    icon: Icons.receipt_long_outlined,
    description: 'Summarise all recorded expenses by category over a selected date range.',
  ),
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
  String _selectedRange = 'This Month';
  bool _reportGenerated = false;

  void _generateReport(_ReportType report) {
    final screenWidth = MediaQuery.of(context).size.width;
    const snackBarWidth = 420.0;
    final leftMargin =
        screenWidth > snackBarWidth + 48 ? screenWidth - snackBarWidth - 24 : 24.0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${report.label} generated for $_selectedRange',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: _kPrimary,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 24, right: 24, left: leftMargin),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
        duration: const Duration(seconds: 3),
      ),
    );
    setState(() => _reportGenerated = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExecutiveHeader(
              title: 'Reports',
              subtitle: 'Choose a report type, configure filters, then generate a focused on-screen report.',
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── LEFT: Report Builder Sidebar ─────────────────────────────
                SizedBox(
                  width: 280,
                  child: _buildSidebar(),
                ),
                const SizedBox(width: 24),
                // ── RIGHT: Preview / Empty State ─────────────────────────────
                Expanded(child: _buildPreviewPanel()),
              ],
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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bar_chart_rounded, color: _kPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Builder',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B)),
                    ),
                    Text(
                      '${_reportTypes.length} report types',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              'Choose a report type, configure filters, then generate a focused on-screen report.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500, height: 1.5),
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
          // Report Type List
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
                      _reportGenerated = false;
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
      constraints: const BoxConstraints(minHeight: 500),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: _selectedIndex == null
          ? _buildEmptyState()
          : _reportGenerated
              ? _buildGeneratedReport(_reportTypes[_selectedIndex!])
              : _buildSelectedState(_reportTypes[_selectedIndex!]),
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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.bar_chart_rounded, color: _kPrimary, size: 36),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select report type',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B)),
            ),
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

  Widget _buildSelectedState(_ReportType report) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(report.icon, color: _kPrimary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.label,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.description,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 28),

          // Date range filter
          const Text(
            'Date Range',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final range in ['Today', 'This Week', 'This Month', 'This Year', 'Custom'])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _DateFilterChip(
                      label: range,
                      isSelected: _selectedRange == range,
                      onTap: () => setState(() => _selectedRange = range),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),

          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _generateReport(report),
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text('Generate ${report.label}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GENERATED REPORT VIEW
  // ---------------------------------------------------------------------------
  Widget _buildGeneratedReport(_ReportType report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(report.icon, color: _kPrimary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.label,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
                    Text('Period: ',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _reportGenerated = false),
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Change Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: BorderSide(color: _kPrimary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatCard('Total Revenue', 'Rs. 1,84,250', Icons.attach_money_rounded, const Color(0xFF0F4C81), '+12.4%', true),
              const SizedBox(width: 12),
              _buildStatCard('Total Sales', '238', Icons.receipt_long_outlined, const Color(0xFF1976D2), '+8.1%', true),
              const SizedBox(width: 12),
              _buildStatCard('Items Sold', '1,042', Icons.medication_outlined, const Color(0xFF2E7D32), '+5.3%', true),
              const SizedBox(width: 12),
              _buildStatCard('Avg Sale', 'Rs. 774', Icons.trending_up_rounded, const Color(0xFF7B1FA2), '-2.1%', false),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('Transactions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
              const Spacer(),
              Text('Showing 8 of 238 records', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 12),
          _buildDummyTable(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, String change, bool isUp) {
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
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isUp ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(change, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                      color: isUp ? Colors.green.shade700 : Colors.red.shade600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildDummyTable() {
    const headers = ['Date', 'Reference', 'Description', 'Type', 'Amount'];
    final rows = [
      ['28 Jun 2026', 'INV-0238', 'Panadol 500mg x10', 'Sale', 'Rs. 450'],
      ['28 Jun 2026', 'INV-0237', 'Augmentin 625mg x6', 'Sale', 'Rs. 1,320'],
      ['27 Jun 2026', 'PAY-0084', 'Customer Payment', 'Payment', 'Rs. 2,000'],
      ['27 Jun 2026', 'INV-0235', 'Brufen 400mg x12', 'Sale', 'Rs. 780'],
      ['26 Jun 2026', 'SR-0019', 'Return: Metformin 500mg', 'Return', '-Rs. 240'],
      ['26 Jun 2026', 'INV-0233', 'Ciplox 500mg x8', 'Sale', 'Rs. 960'],
      ['25 Jun 2026', 'INV-0230', 'Paracetamol Syrup x4', 'Sale', 'Rs. 320'],
      ['24 Jun 2026', 'PAY-0081', 'Customer Payment', 'Payment', 'Rs. 5,000'],
    ];
    final typeColors = {
      'Sale': const Color(0xFF1976D2),
      'Payment': const Color(0xFF2E7D32),
      'Return': const Color(0xFFC62828),
    };

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(3),
            3: FlexColumnWidth(1.5),
            4: FlexColumnWidth(2),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade50),
              children: headers.map((h) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(h, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600, letterSpacing: 0.3)),
                  )).toList(),
            ),
            ...rows.asMap().entries.map((e) {
              final i = e.key;
              final row = e.value;
              final type = row[3];
              final typeColor = typeColors[type] ?? Colors.grey;
              return TableRow(
                decoration: BoxDecoration(
                  color: i.isEven ? Colors.white : Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade100)),
                ),
                children: [
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Text(row[0], style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Text(row[1], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B)))),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Text(row[2], style: TextStyle(fontSize: 13, color: Colors.grey.shade800))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(type, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: typeColor)),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Text(row[4], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: row[4].startsWith('-') ? Colors.red.shade600 : Colors.green.shade700))),
                ],
              );
            }),
          ],
        ),
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

  const _ReportTypeItem({
    required this.report,
    required this.isSelected,
    required this.onTap,
  });

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
            color: selected
                ? _kPrimary.withValues(alpha: 0.08)
                : _hovered
                    ? Colors.grey.shade50
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? _kPrimary.withValues(alpha: 0.3) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.report.icon,
                size: 18,
                color: selected ? _kPrimary : Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.report.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? _kPrimary : const Color(0xFF1A2E2B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected)
                const Icon(Icons.chevron_right_rounded, size: 16, color: _kPrimary),
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
            color: widget.isSelected
                ? _kPrimary
                : _hovered
                    ? Colors.grey.shade100
                    : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isSelected ? _kPrimary : Colors.grey.shade200,
            ),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: widget.isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
