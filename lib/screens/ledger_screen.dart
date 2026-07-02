import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/database_helper.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/expense.dart';

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

  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    return LedgerEntry(
      date: DateTime.parse(map['date']),
      title: map['reference'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      type: map['type'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
    );
  }
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

  factory CustomerStatementEntry.fromMap(Map<String, dynamic> map) {
    return CustomerStatementEntry(
      date: DateTime.parse(map['date']),
      reference: map['reference'] ?? '',
      description: map['description'] ?? '',
      debit: (map['debit'] ?? 0).toDouble(),
      credit: (map['credit'] ?? 0).toDouble(),
      balance: (map['balance'] ?? 0).toDouble(),
    );
  }
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

  factory SupplierStatementEntry.fromMap(Map<String, dynamic> map) {
    return SupplierStatementEntry(
      date: DateTime.parse(map['date']),
      reference: map['reference'] ?? '',
      description: map['description'] ?? '',
      debit: (map['debit'] ?? 0).toDouble(),
      credit: (map['credit'] ?? 0).toDouble(),
      balance: (map['balance'] ?? 0).toDouble(),
    );
  }
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
    return '$start - $end';
  }

  bool _isLoading = true;

  List<LedgerEntry> _generalLedger = [];
  List<CustomerStatementEntry> _customerStatements = [];
  List<SupplierStatementEntry> _supplierStatements = [];

  List<Customer> _customers = [];
  List<Supplier> _suppliers = [];

  String? _selectedCustomerId;
  String? _selectedSupplierId;

  Customer? get _selectedCustomerObj => _customers.where((c) => c.id == _selectedCustomerId).firstOrNull;
  Supplier? get _selectedSupplierObj => _suppliers.where((s) => s.id == _selectedSupplierId).firstOrNull;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadInitialData();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadDataForCurrentTab();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // Load accounts
      _customers = await DatabaseHelper.instance.getCustomers();
      _suppliers = await DatabaseHelper.instance.getSuppliers();
      
      if (_customers.isNotEmpty) _selectedCustomerId = _customers.first.id;
      if (_suppliers.isNotEmpty) _selectedSupplierId = _suppliers.first.id;

      await _loadDataForCurrentTab();
    } catch (e) {
      debugPrint('LedgerScreen _loadInitialData error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDataForCurrentTab() async {
    setState(() => _isLoading = true);
    try {
      if (_tabController.index == 0) {
        final data = await DatabaseHelper.instance.getGeneralLedger(_selectedDateRange?.start, _selectedDateRange?.end);
        _generalLedger = data.map((e) => LedgerEntry.fromMap(e)).toList();
      } else if (_tabController.index == 1) {
        if (_selectedCustomerId != null) {
          final data = await DatabaseHelper.instance.getCustomerStatement(_selectedCustomerId!, _selectedDateRange?.start, _selectedDateRange?.end);
          _customerStatements = data.map((e) => CustomerStatementEntry.fromMap(e)).toList();
        }
      } else if (_tabController.index == 2) {
        if (_selectedSupplierId != null) {
          final data = await DatabaseHelper.instance.getSupplierStatement(_selectedSupplierId!, _selectedDateRange?.start, _selectedDateRange?.end);
          _supplierStatements = data.map((e) => SupplierStatementEntry.fromMap(e)).toList();
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
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
      _loadDataForCurrentTab();
    }
  }

  void _syncNow() {
    // TODO: Wire "Sync now" to trigger actual SQLite-to-Firestore sync and update the "Updated [time]" timestamp
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing data to Firebase...')));
  }

  Future<void> _addExpense() async {
    await showDialog(
      context: context,
      builder: (context) => const _AddExpenseDialog(),
    );
    _loadDataForCurrentTab();
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    // --- Dynamic summary computation ---
    final fmt = NumberFormat('#,##0.00', 'en_US');
    final inflow = _generalLedger
        .where((e) => e.type == 'SALE' || e.type == 'REFUND')
        .fold(0.0, (sum, e) => sum + e.amount.abs());
    final outflow = _generalLedger
        .where((e) => e.type == 'EXPENSE' || e.type == 'PURCHASE')
        .fold(0.0, (sum, e) => sum + e.amount.abs());
    final opening = 0.0; // Could be fetched from a settings table in future
    final closing = opening + inflow - outflow;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(child: _SummaryStatCard(title: 'Opening', amount: 'Rs. ${fmt.format(opening)}', icon: Icons.flag, bgColor: Colors.grey.shade100, iconColor: Colors.grey.shade700, textColor: _primary)),
            const SizedBox(width: 16),
            Expanded(child: _SummaryStatCard(title: 'Inflow', amount: 'Rs. ${fmt.format(inflow)}', icon: Icons.call_received, bgColor: Colors.green.shade50, iconColor: Colors.green.shade700, textColor: Colors.green.shade700)),
            const SizedBox(width: 16),
            Expanded(child: _SummaryStatCard(title: 'Outflow', amount: 'Rs. ${fmt.format(outflow)}', icon: Icons.call_made, bgColor: Colors.red.shade50, iconColor: Colors.red.shade700, textColor: Colors.red.shade700)),
            const SizedBox(width: 16),
            Expanded(child: _SummaryStatCard(title: 'Closing', amount: 'Rs. ${fmt.format(closing)}', icon: Icons.account_balance_wallet, bgColor: _primary.withValues(alpha: 0.05), iconColor: _primary, textColor: _primary)),
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final entries = _customerStatements;
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Action Bar for Tab 2
        Row(
          children: [
            _AccountSelector(
              icon: Icons.person_outline,
              value: _selectedCustomerId,
              items: _customers.isEmpty 
                  ? const [DropdownMenuItem<String>(value: null, child: Text('No customers'))]
                  : _customers.map((c) => DropdownMenuItem<String>(value: c.id, child: Text(c.name))).toList(),
              onChanged: _customers.isEmpty ? null : (val) {
                if (val != null) {
                  setState(() => _selectedCustomerId = val);
                  _loadDataForCurrentTab();
                }
              },
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _selectedCustomerObj == null ? null : () => _printCustomerStatement(_selectedCustomerObj!),
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
                    Text(_selectedCustomerObj?.name ?? 'No Customer Selected', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _primary)),
                    Text(_selectedCustomerObj?.phone ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              _StatementPill(
                label: 'Advance Credit: Rs. ${NumberFormat('#,##0.00').format(_selectedCustomerObj?.advanceAmount ?? 0)}',
                color: Colors.green.shade700, bgColor: Colors.green.shade50,
              ),
              const SizedBox(width: 8),
              _StatementPill(
                label: 'Outstanding Balance: Rs. ${NumberFormat('#,##0.00').format(_customerStatements.isNotEmpty ? _customerStatements.first.balance : (_selectedCustomerObj?.pendingAmount ?? 0))}',
                color: Colors.grey.shade700, bgColor: Colors.grey.shade100,
              ),
              const SizedBox(width: 8),
              _StatementPill(
                label: 'Balance: Rs. ${NumberFormat('#,##0.00').format(_customerStatements.isNotEmpty ? _customerStatements.first.balance : (_selectedCustomerObj?.pendingAmount ?? 0))}',
                color: _primary, bgColor: _primary.withValues(alpha: 0.05),
              ),
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final entries = _supplierStatements;
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Action Bar for Tab 3
        Row(
          children: [
            _AccountSelector(
              icon: Icons.business_outlined,
              value: _selectedSupplierId,
              items: _suppliers.isEmpty 
                  ? const [DropdownMenuItem<String>(value: null, child: Text('No suppliers'))]
                  : _suppliers.map((s) => DropdownMenuItem<String>(value: s.id, child: Text(s.companyName))).toList(),
              onChanged: _suppliers.isEmpty ? null : (val) {
                if (val != null) {
                  setState(() => _selectedSupplierId = val);
                  _loadDataForCurrentTab();
                }
              },
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _selectedSupplierObj == null ? null : () => _printSupplierStatement(_selectedSupplierObj!),
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
                    Text(_selectedSupplierObj?.companyName ?? 'No Supplier Selected', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _primary)),
                    Text(_selectedSupplierObj?.contactPerson ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              _StatementPill(
                label: 'Total Paid: Rs. ${NumberFormat('#,##0.00').format(_supplierStatements.fold(0.0, (s, e) => s + e.credit))}',
                color: Colors.green.shade700, bgColor: Colors.green.shade50,
              ),
              const SizedBox(width: 8),
              _StatementPill(
                label: 'Total Payable: Rs. ${NumberFormat('#,##0.00').format(_supplierStatements.fold(0.0, (s, e) => s + e.debit))}',
                color: Colors.grey.shade700, bgColor: Colors.grey.shade100,
              ),
              const SizedBox(width: 8),
              _StatementPill(
                label: 'Balance: Rs. ${NumberFormat('#,##0.00').format(_supplierStatements.isNotEmpty ? _supplierStatements.first.balance : (_selectedSupplierObj?.pendingAmount ?? 0))}',
                color: _primary, bgColor: _primary.withValues(alpha: 0.05),
              ),
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
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.w600)
                )
              ),
              Expanded(
                flex: 1, 
                child: Text(
                  e.credit > 0 ? 'Rs. ${e.credit.toStringAsFixed(2)}' : '-', 
                  style: TextStyle(color: Colors.green.shade700, fontSize: 13, fontWeight: FontWeight.w600)
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

  // ---------------------------------------------------------------------------
  // PDF GENERATION
  // ---------------------------------------------------------------------------
  Future<void> _printCustomerStatement(Customer customer) async {
    final entries = _customerStatements;
    final pdf = pw.Document();
    final dateRange = _selectedDateRange == null
        ? 'All Time'
        : '${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Customer Receivable Statement',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Period: $dateRange', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Text('Sohail Medical Store',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 8),
          // Customer Info
          pw.Row(
            children: [
              pw.Text('Customer: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(customer.name),
              pw.SizedBox(width: 24),
              pw.Text('Phone: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(customer.phone),
            ],
          ),
          pw.SizedBox(height: 16),
          // Table Header
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
              5: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  for (final h in ['Date', 'Reference', 'Description', 'Debit (Owed)', 'Credit (Paid)', 'Balance'])
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                ],
              ),
              for (final e in entries)
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(DateFormat('dd/MM/yyyy').format(e.date), style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.reference, style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.description, style: const pw.TextStyle(fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.debit > 0 ? 'Rs. ${e.debit.toStringAsFixed(2)}' : '-', style: const pw.TextStyle(fontSize: 9, color: PdfColors.red))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.credit > 0 ? 'Rs. ${e.credit.toStringAsFixed(2)}' : '-', style: const pw.TextStyle(fontSize: 9, color: PdfColors.green))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Rs. ${e.balance.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          // Totals
          if (entries.isNotEmpty)
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Outstanding Balance: Rs. ${NumberFormat('#,##0.00').format(entries.first.balance)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Closing Balance: Rs. ${NumberFormat('#,##0.00').format(entries.first.balance)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> _printSupplierStatement(Supplier supplier) async {
    final entries = _supplierStatements;
    final pdf = pw.Document();
    final dateRange = _selectedDateRange == null
        ? 'All Time'
        : '${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Supplier Payable Statement',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Period: $dateRange', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Text('Sohail Medical Store',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 8),
          // Supplier Info
          pw.Row(
            children: [
              pw.Text('Supplier: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(supplier.companyName),
              pw.SizedBox(width: 24),
              pw.Text('Contact: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(supplier.contactPerson),
            ],
          ),
          pw.SizedBox(height: 16),
          // Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
              5: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  for (final h in ['Date', 'Reference', 'Description', 'Debit (Owed)', 'Credit (Paid)', 'Balance'])
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                ],
              ),
              for (final e in entries)
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(DateFormat('dd/MM/yyyy').format(e.date), style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.reference, style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.description, style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.debit > 0 ? 'Rs. ${e.debit.toStringAsFixed(2)}' : '-', style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.credit > 0 ? 'Rs. ${e.credit.toStringAsFixed(2)}' : '-', style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Rs. ${e.balance.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 12),
          // Totals
          if (entries.isNotEmpty)
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Total Payable: Rs. ${NumberFormat('#,##0.00').format(entries.fold(0.0, (s, e) => s + e.debit))}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Closing Balance: Rs. ${NumberFormat('#,##0.00').format(entries.last.balance)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
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
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;

  const _AccountSelector({
    required this.icon,
    required this.value,
    required this.items,
    this.onChanged,
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
              items: items,
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
                  onPressed: () async {
                    final amount = double.tryParse(_amountController.text) ?? 0.0;
                    if (amount <= 0) return;
                    
                    final expense = Expense(
                      title: _titleController.text.trim(),
                      category: _category,
                      amount: amount,
                      notes: _notesController.text.trim(),
                      date: DateTime.now().toIso8601String(),
                    );
                    
                    await DatabaseHelper.instance.insertExpense(expense);
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
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
