import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// MODELS
// ---------------------------------------------------------------------------
class LedgerEntry {
  final DateTime date;
  final String title;
  final String description;
  final String category;
  final String type; // e.g. "SALE", "EXPENSE", "PURCHASE", "REFUND"
  final double amount;

  LedgerEntry({
    required this.date,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.amount,
  });
}

class CustomerStatementEntry {
  final DateTime date;
  final String reference;
  final String description;
  final double debit; // Owed
  final double credit; // Paid
  final double balance;

  CustomerStatementEntry({
    required this.date,
    required this.reference,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
  });
}

class SupplierStatementEntry {
  final DateTime date;
  final String reference;
  final String description;
  final double debit; // Owed
  final double credit; // Paid
  final double balance;

  SupplierStatementEntry({
    required this.date,
    required this.reference,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
  });
}

// ---------------------------------------------------------------------------
// SCREEN
// ---------------------------------------------------------------------------
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> with SingleTickerProviderStateMixin {
  // Theme Tokens
  static const Color _primary = Color(0xFF0F4C81);
  static const Color _accent = Color(0xFF1976D2);
  static const Color _bg = Color(0xFFF4F7F6);
  static const Color _cardBg = Colors.white;

  late TabController _tabController;
  DateTimeRange? _selectedDateRange;

  String get _dateRangeText {
    if (_selectedDateRange == null) return 'All time';
    final start = DateFormat('dd MMM yyyy').format(_selectedDateRange!.start);
    final end = DateFormat('dd MMM yyyy').format(_selectedDateRange!.end);
    return ' - ';
  }


  // Dummy Data for Tab 1 (General Cash Ledger)
  // TODO: Replace dummy general ledger entries with aggregated Firestore stream combining 'sales', 'salesReturns', 'purchaseOrders', and 'expenses' collections, ordered by date
  final List<LedgerEntry> _generalLedger = [
    LedgerEntry(date: DateTime.now().subtract(const Duration(days: 0)), title: 'Sale Invoice', description: 'Sale Invoice: INV-001', category: 'Sales', type: 'SALE', amount: 1250.0),
    LedgerEntry(date: DateTime.now().subtract(const Duration(days: 0)), title: 'Stationery Expense', description: 'Pens, paper, staples', category: 'Office Supplies', type: 'EXPENSE', amount: -250.0),
    LedgerEntry(date: DateTime.now().subtract(const Duration(days: 1)), title: 'Supplier Payment', description: 'Payment for PO-102', category: 'Purchases', type: 'EXPENSE', amount: -4500.0),
    LedgerEntry(date: DateTime.now().subtract(const Duration(days: 1)), title: 'Sale Invoice', description: 'Sale Invoice: INV-002', category: 'Sales', type: 'SALE', amount: 840.0),
    LedgerEntry(date: DateTime.now().subtract(const Duration(days: 2)), title: 'Refund', description: 'Sales Return Refund: SR-001', category: 'Returns', type: 'REFUND', amount: -150.0),
    LedgerEntry(date: DateTime.now().subtract(const Duration(days: 2)), title: 'Sale Invoice', description: 'Sale Invoice: INV-003', category: 'Sales', type: 'SALE', amount: 3200.0),
  ];

  // Dummy Data for Tab 2 (Customer Statements)
  String _selectedCustomer = 'Walk-in Customer (0000000000)';
  // TODO: Replace dummy customer statement with a Firestore query filtered by customerId across 'sales' and 'payments'
  final Map<String, List<CustomerStatementEntry>> _customerStatements = {
    'Walk-in Customer (0000000000)': [
      CustomerStatementEntry(date: DateTime.now().subtract(const Duration(days: 5)), reference: 'INV-100', description: 'Invoice Charge', debit: 500, credit: 0, balance: 500),
      CustomerStatementEntry(date: DateTime.now().subtract(const Duration(days: 5)), reference: 'PAY-100', description: 'Cash Payment', debit: 0, credit: 500, balance: 0),
      CustomerStatementEntry(date: DateTime.now().subtract(const Duration(days: 2)), reference: 'INV-102', description: 'Invoice Charge', debit: 1200, credit: 0, balance: 1200),
      CustomerStatementEntry(date: DateTime.now().subtract(const Duration(days: 1)), reference: 'PAY-102', description: 'Partial Payment', debit: 0, credit: 600, balance: 600),
    ],
    'John Doe (03001234567)': [],
  };

  // Dummy Data for Tab 3 (Supplier Statements)
  String _selectedSupplier = 'PharmaCorp Inc. (03009876543)';
  // TODO: Replace dummy supplier statement with a Firestore query filtered by supplierId across 'purchaseOrders' and 'supplierPayments'
  final Map<String, List<SupplierStatementEntry>> _supplierStatements = {
    'PharmaCorp Inc. (03009876543)': [
      SupplierStatementEntry(date: DateTime.now().subtract(const Duration(days: 10)), reference: 'PO-200', description: 'Purchase Order', debit: 8000, credit: 0, balance: 8000),
      SupplierStatementEntry(date: DateTime.now().subtract(const Duration(days: 8)), reference: 'PAY-200', description: 'Advance Payment', debit: 0, credit: 4000, balance: 4000),
      SupplierStatementEntry(date: DateTime.now().subtract(const Duration(days: 1)), reference: 'PAY-201', description: 'Final Settlement', debit: 0, credit: 4000, balance: 0),
    ],
    'MediSupply Co. (03211234567)': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _syncNow() {
    // TODO: Wire "Sync now" to trigger actual SQLite-to-Firestore sync and update the "Updated [time]" timestamp
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing data to Firebase...')));
  }

  void _addExpense() {
    showDialog(
      context: context,
      builder: (context) => const _AddExpenseDialog(),
    );
  }

  void _exportCSV() {
    // TODO: Implement real CSV export logic for "Export CSV" button
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting CSV...')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. PAGE HEADER ROW
          _buildHeaderRow(),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 2. FILTER/ACTION BAR & 3. TABS ROW
                  _buildFilterAndTabsBar(),
                  
                  const SizedBox(height: 24),
                  
                  // TAB VIEWS (AnimatedSwitcher to simulate TabBarView without bounding box issues in a scrollable view)
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildCurrentTab(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_tabController.index) {
      case 0:
        return _buildGeneralCashLedgerTab(key: const ValueKey(0));
      case 1:
        return _buildCustomerStatementsTab(key: const ValueKey(1));
      case 2:
        return _buildSupplierStatementsTab(key: const ValueKey(2));
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------------------
  // 1. HEADER ROW
  // ---------------------------------------------------------------------------
  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ledger Workspace',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track cash movement, customer receivables, and supplier liabilities in one accounting-grade surface.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Right: Status Elements
          Row(
            children: [
              _buildStatusCard(
                icon: Icons.calendar_today_outlined,
                title: 'Reporting date',
                subtitle: DateFormat('dd MMM yyyy').format(DateTime.now()),
                iconColor: _accent,
              ),
              const SizedBox(width: 16),
              _buildStatusCard(
                icon: Icons.cloud_done_outlined,
                title: 'Data synced',
                subtitle: 'Updated just now',
                iconColor: Colors.green,
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _syncNow,
                icon: const Icon(Icons.sync, size: 18),
                label: const Text('Sync now'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: _primary),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({required IconData icon, required String title, required String subtitle, required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primary)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2 & 3. FILTER / ACTION / TABS BAR
  // ---------------------------------------------------------------------------
  Widget _buildFilterAndTabsBar() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildFilterButton(
                  icon: Icons.calendar_month_outlined,
                  text: _dateRangeText,
                  showTrailingX: _selectedDateRange != null,
                  onTap: _pickDateRange,
                  onClear: () => setState(() => _selectedDateRange = null),
                  label: 'Date range',
                ),
                const SizedBox(width: 12),
                _buildFilterButton(
                  icon: Icons.filter_alt_outlined,
                  text: 'All transaction types',
                  showTrailingX: false,
                  onTap: () {},
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _exportCSV,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Export CSV'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _addExpense,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Expense'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: Colors.grey.shade100),
          
          // Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: _primary,
            unselectedLabelColor: Colors.grey.shade500,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            indicatorColor: _primary,
            indicatorWeight: 3,
            dividerColor: Colors.transparent,
            splashBorderRadius: BorderRadius.circular(8),
            tabs: const [
              Tab(text: 'General Cash Ledger'),
              Tab(text: 'Customer Statements'),
              Tab(text: 'Supplier Statements'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({required IconData icon, required String text, required bool showTrailingX, required VoidCallback onTap, VoidCallback? onClear, String? label}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null) Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  Text(
                    text,
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              if (showTrailingX)
                InkWell(
                  onTap: onClear,
                  child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                )
              else
                Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: GENERAL CASH LEDGER
  // ---------------------------------------------------------------------------
  Widget _buildGeneralCashLedgerTab({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(child: _SummaryStatCard(title: 'Opening', amount: 'Rs. 50,000', icon: Icons.flag, bgColor: Colors.grey.shade100, iconColor: Colors.grey.shade700, textColor: _primary)),
            const SizedBox(width: 16),
            Expanded(child: _SummaryStatCard(title: 'Inflow', amount: 'Rs. 25,000', icon: Icons.call_received, bgColor: Colors.green.shade50, iconColor: Colors.green.shade700, textColor: Colors.green.shade700)),
            const SizedBox(width: 16),
            Expanded(child: _SummaryStatCard(title: 'Outflow', amount: 'Rs. 10,000', icon: Icons.call_made, bgColor: Colors.red.shade50, iconColor: Colors.red.shade700, textColor: Colors.red.shade700)),
            const SizedBox(width: 16),
            Expanded(child: _SummaryStatCard(title: 'Closing', amount: 'Rs. 65,000', icon: Icons.account_balance_wallet, bgColor: _primary.withValues(alpha: 0.05), iconColor: _primary, textColor: _primary)),
          ],
        ),
        const SizedBox(height: 24),
        // Transactions Table
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTableHeader(['DATE', 'TITLE & DESCRIPTION', 'CATEGORY', 'TYPE', 'AMOUNT']),
              if (_generalLedger.isEmpty) _buildEmptyState('No ledger entries found.'),
              for (var entry in _generalLedger) _buildGeneralLedgerRow(entry),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralLedgerRow(LedgerEntry entry) {
    Color typeColor;
    switch (entry.type) {
      case 'SALE': typeColor = Colors.green; break;
      case 'EXPENSE': typeColor = Colors.red; break;
      case 'PURCHASE': typeColor = Colors.orange; break;
      case 'REFUND': typeColor = Colors.purple; break;
      default: typeColor = Colors.grey; break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        hoverColor: Colors.grey.shade50,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              Expanded(flex: 1, child: Text(DateFormat('dd MMM yyyy, HH:mm').format(entry.date), style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w600, color: _primary, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(entry.description, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(flex: 2, child: Text(entry.category, style: TextStyle(color: Colors.grey.shade800, fontSize: 13))),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.type,
                      style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Rs. ${entry.amount.abs().toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: entry.amount >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: CUSTOMER STATEMENTS
  // ---------------------------------------------------------------------------
  Widget _buildCustomerStatementsTab({Key? key}) {
    final entries = _customerStatements[_selectedCustomer] ?? [];
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Action Bar for Tab 2
        Row(
          children: [
            _AccountSelector(
              icon: Icons.person_outline,
              value: _selectedCustomer,
              items: _customerStatements.keys.toList(),
              onChanged: (val) => setState(() => _selectedCustomer = val!),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Receivable statement'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _primary),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Info Row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedCustomer.split('(')[0].trim(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _primary)),
                    Text(_selectedCustomer, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              _StatementPill(label: 'Advance Credit: Rs. 0', color: Colors.green.shade700, bgColor: Colors.green.shade50),
              const SizedBox(width: 8),
              _StatementPill(label: 'Opening Rs. 500', color: Colors.grey.shade700, bgColor: Colors.grey.shade100),
              const SizedBox(width: 8),
              _StatementPill(label: 'Closing Rs. 600', color: _primary, bgColor: _primary.withValues(alpha: 0.05)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Statement Table
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTableHeader(['DATE', 'REFERENCE', 'DESCRIPTION', 'DEBIT (PAID)', 'CREDIT (OWED)', 'BALANCE']),
              if (entries.isEmpty) _buildEmptyState('No customer ledger activity yet'),
              for (var entry in entries) _buildStatementRow(entry, true),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: SUPPLIER STATEMENTS
  // ---------------------------------------------------------------------------
  Widget _buildSupplierStatementsTab({Key? key}) {
    final entries = _supplierStatements[_selectedSupplier] ?? [];
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Action Bar for Tab 3
        Row(
          children: [
            _AccountSelector(
              icon: Icons.business_outlined,
              value: _selectedSupplier,
              items: _supplierStatements.keys.toList(),
              onChanged: (val) => setState(() => _selectedSupplier = val!),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Payable statement'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _primary),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Info Row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedSupplier.split('(')[0].trim(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _primary)),
                    Text(_selectedSupplier, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              _StatementPill(label: 'Settled: Rs. 8000', color: Colors.green.shade700, bgColor: Colors.green.shade50),
              const SizedBox(width: 8),
              _StatementPill(label: 'Opening Rs. 8000', color: Colors.grey.shade700, bgColor: Colors.grey.shade100),
              const SizedBox(width: 8),
              _StatementPill(label: 'Closing Rs. 0', color: _primary, bgColor: _primary.withValues(alpha: 0.05)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Statement Table
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTableHeader(['DATE', 'REFERENCE', 'DESCRIPTION', 'DEBIT (OWED)', 'CREDIT (PAID)', 'BALANCE']),
              if (entries.isEmpty) _buildEmptyState('No supplier ledger activity yet'),
              for (var entry in entries) _buildStatementRow(entry, false),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // REUSABLE COMPONENTS
  // ---------------------------------------------------------------------------
  Widget _buildTableHeader(List<String> columns) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: columns.map((col) {
          final isLast = columns.last == col;
          final flex = (col == 'TITLE & DESCRIPTION' || col == 'DESCRIPTION') ? 3 : (col == 'CATEGORY' ? 2 : 1);
          return Expanded(
            flex: flex,
            child: Text(
              col,
              textAlign: isLast ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatementRow(dynamic entry, bool isCustomer) {
    final e = entry; // dynamic to reuse UI for Customer/Supplier
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        hoverColor: Colors.grey.shade50,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              Expanded(flex: 1, child: Text(DateFormat('dd MMM yyyy').format(e.date), style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
              Expanded(flex: 1, child: Text(e.reference, style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w500))),
              Expanded(flex: 3, child: Text(e.description, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
              Expanded(
                flex: 1, 
                child: Text(
                  e.debit > 0 ? 'Rs. ${e.debit.toStringAsFixed(2)}' : '-', 
                  style: TextStyle(color: isCustomer ? Colors.green.shade700 : Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.w600)
                )
              ),
              Expanded(
                flex: 1, 
                child: Text(
                  e.credit > 0 ? 'Rs. ${e.credit.toStringAsFixed(2)}' : '-', 
                  style: TextStyle(color: isCustomer ? Colors.red.shade700 : Colors.green.shade700, fontSize: 13, fontWeight: FontWeight.w600)
                )
              ),
              Expanded(
                flex: 1, 
                child: Text(
                  'Rs. ${e.balance.toStringAsFixed(2)}', 
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: _primary, fontSize: 14, fontWeight: FontWeight.w700)
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.description_outlined, size: 32, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SMALL COMPONENTS
// ---------------------------------------------------------------------------
class _SummaryStatCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final Color textColor;

  const _SummaryStatCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Text(amount, style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AccountSelector extends StatelessWidget {
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _AccountSelector({
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
              style: TextStyle(color: Colors.grey.shade800, fontSize: 14, fontWeight: FontWeight.w600),
              onChanged: onChanged,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatementPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _StatementPill({required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}


class _AddExpenseDialog extends StatefulWidget {
  const _AddExpenseDialog();

  @override
  State<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<_AddExpenseDialog> {
  String _category = 'Rent';
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A66F9).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.money, color: Color(0xFF5A66F9), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add New Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F4C81))),
                      const SizedBox(height: 2),
                      Text('Record an operational cost and deduct from ledger', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.grey.shade500,
                  splashRadius: 24,
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 24),
            const Text('Expense Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF5A66F9))),
              ),
              items: ['Rent', 'Utilities', 'Salaries', 'Office Supplies', 'Marketing', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            const Text('Title / Reference', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g. Electricity Bill May 2026',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF5A66F9))),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Amount (Rs.)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 5000',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF5A66F9))),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Notes / Remarks', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Paid via bank transfer',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF5A66F9))),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Write expense to SQLite/Firestore
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A66F9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Add Expense'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
