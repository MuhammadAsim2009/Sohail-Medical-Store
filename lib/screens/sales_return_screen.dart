import 'package:flutter/material.dart';
import '../widgets/executive_header.dart';
import '../models/sales_return.dart';
import '../models/daily_sales_sheet.dart';
import '../models/sale.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../services/database_helper.dart';

// ---------------------------------------------------------------------------
// THEME TOKENS
// ---------------------------------------------------------------------------
const _kPrimary = Color(0xFF0F4C81);
const _kBg = Color(0xFFF5F7FA);

// ---------------------------------------------------------------------------
// SALES RETURN SCREEN
// ---------------------------------------------------------------------------
class SalesReturnScreen extends StatefulWidget {
  const SalesReturnScreen({super.key});

  @override
  State<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends State<SalesReturnScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'All posted';
  bool _dssOpen = false;

  DailySalesSheet? _currentDSS;
  List<SalesReturn> _returns = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dss = await DatabaseHelper.instance.getCurrentOpenDSS();
    final returns = await DatabaseHelper.instance.getAllSalesReturns();
    setState(() {
      _currentDSS = dss;
      _dssOpen = dss != null;
      _returns = returns;
    });
  }

  List<SalesReturn> get _filtered {
    final q = _searchQuery.trim().toLowerCase();
    return _returns.where((r) {
      if (q.isNotEmpty) {
        return r.id.toString().contains(q) ||
            r.invoiceNumber.toLowerCase().contains(q) ||
            (r.customerName ?? '').toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  double get _postedReturnValue =>
      _returns.where((r) => r.status == 'Posted').fold(0, (s, r) => s + r.totalRefund);
  double get _cashRefunded => _returns.fold(0, (s, r) => s + r.cashRefunded);
  double get _customerCredit => _returns.fold(0, (s, r) => s + r.creditIssued);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ExecutiveHeader(
                    title: 'Sales Return',
                    subtitle: 'Manage returned invoices, refund review, and stock reversal workflows from one\ndedicated surface.',
                  ),
                  const SizedBox(height: 28),
                  if (_dssOpen) _buildDSSBanner(),
                  if (_dssOpen) const SizedBox(height: 20),
                  _buildStatCards(),
                  const SizedBox(height: 20),
                  _buildActionBar(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  _buildTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDSSBanner() {
    if (_currentDSS == null) return const SizedBox.shrink();
    final dssDate = DateTime.parse(_currentDSS!.date);
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = '${dssDate.day} ${months[dssDate.month - 1]} ${dssDate.year}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.event_available_rounded, color: Colors.green.shade600, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Sales Sheet Open', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('DSS-${_currentDSS!.id}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    _dot(),
                    Text(dateStr, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Text('◆', style: TextStyle(fontSize: 8, color: Colors.grey.shade400)),
  );

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(child: _StatCard(title: 'Posted return value', value: 'Rs. ${_postedReturnValue.toStringAsFixed(0)}', subtitle: '${_returns.where((r) => r.status == "Posted").length} posted returns', iconBg: const Color(0xFFFFF3E0), icon: Icons.assignment_return_rounded, iconColor: const Color(0xFFF57C00))),
        const SizedBox(width: 16),
        Expanded(child: _StatCard(title: 'Cash refunded', value: 'Rs. ${_cashRefunded.toStringAsFixed(0)}', subtitle: 'Total cash returned to customers', iconBg: const Color(0xFFFFEBEE), icon: Icons.payments_rounded, iconColor: const Color(0xFFE53935))),
        const SizedBox(width: 16),
        Expanded(child: _StatCard(title: 'Customer credit', value: 'Rs. ${_customerCredit.toStringAsFixed(0)}', subtitle: 'Exchange and balance returns retained', iconBg: const Color(0xFFE3F2FD), icon: Icons.account_balance_wallet_rounded, iconColor: const Color(0xFF1976D2))),
      ],
    );
  }

  Widget _buildActionBar() {
    return Row(
      children: [
        _FilterChip(label: '${_filtered.length} return records', icon: Icons.receipt_long_outlined, selected: false, onTap: () {}),
        const SizedBox(width: 8),
        _FilterChip(label: 'All posted', icon: Icons.check_circle_outline, selected: _activeFilter == 'All posted', selectedColor: Colors.green, onTap: () => setState(() => _activeFilter = 'All posted')),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _showNewReturnDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Return', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by return or invoice number',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final rows = _filtered;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
        border: Border(
          left: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.grey.shade50, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
            child: const Row(
              children: [
                _ColHeader('RETURN', flex: 2),
                _ColHeader('DATE', flex: 2),
                _ColHeader('INVOICE', flex: 2),
                _ColHeader('CUSTOMER', flex: 3),
                _ColHeader('MODE', flex: 2),
                _ColHeader('TOTAL', flex: 2),
                _ColHeader('CASH', flex: 2),
                _ColHeader('CREDIT', flex: 2),
                _ColHeader('STATUS', flex: 2),
                _ColHeader('ACTIONS', flex: 2),
              ],
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.assignment_return_outlined, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No return records yet', style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('Click "+ New Return" to record your first return', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ...rows.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
            final dateStr = '${r.date.day} ${months[r.date.month - 1]} ${r.date.year}';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: i.isEven ? Colors.white : Colors.grey.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  _Col('RET-${r.id}', flex: 2, bold: true, color: _kPrimary),
                  _Col(dateStr, flex: 2),
                  _Col(r.invoiceNumber, flex: 2),
                  _Col(r.customerName ?? 'Walk-in', flex: 3),
                  _Col(r.mode, flex: 2),
                  _Col('Rs. ${r.totalRefund.toStringAsFixed(0)}', flex: 2),
                  _Col('Rs. ${r.cashRefunded.toStringAsFixed(0)}', flex: 2),
                  _Col('Rs. ${r.creditIssued.toStringAsFixed(0)}', flex: 2),
                  Expanded(flex: 2, child: _StatusBadge(r.status)),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Tooltip(
                          message: 'View details',
                          child: InkWell(
                            onTap: () => _showViewReturnDialog(r),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF3FB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.visibility_outlined, size: 16, color: _kPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Delete return',
                          child: InkWell(
                            onTap: () => _showDeleteReturnDialog(r),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade500),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showNewReturnDialog() {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _NewReturnDialog(
        dssId: _currentDSS?.id,
        onReturnProcessed: _loadData,
      ),
    );
  }

  void _showViewReturnDialog(SalesReturn r) {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _ViewReturnDialog(salesReturn: r),
    );
  }

  void _showDeleteReturnDialog(SalesReturn r) {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _DeleteReturnDialog(
        salesReturn: r,
        onDeleted: _loadData,
      ),
    );
  }

}

// ---------------------------------------------------------------------------
// STAT CARD
// ---------------------------------------------------------------------------
class _StatCard extends StatelessWidget {
  final String title, value, subtitle;
  final Color iconBg, iconColor;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.subtitle, required this.iconBg, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 22)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A2E2B), letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FILTER CHIP
// ---------------------------------------------------------------------------
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color? selectedColor;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.icon, required this.selected, this.selectedColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? Colors.grey.shade700;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color.withValues(alpha: 0.4) : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? color : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, color: selected ? color : Colors.grey.shade700, fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TABLE HELPERS
// ---------------------------------------------------------------------------
class _ColHeader extends StatelessWidget {
  final String label;
  final int flex;
  const _ColHeader(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(flex: flex, child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5)));
  }
}

class _Col extends StatelessWidget {
  final String text;
  final int flex;
  final bool bold;
  final Color? color;
  const _Col(this.text, {required this.flex, this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text, style: TextStyle(fontSize: 13, color: color ?? const Color(0xFF1A2E2B), fontWeight: bold ? FontWeight.w600 : FontWeight.w400), overflow: TextOverflow.ellipsis),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case 'Posted': bg = Colors.green.shade50; fg = Colors.green.shade700; break;
      case 'Draft': bg = Colors.orange.shade50; fg = Colors.orange.shade700; break;
      case 'Cancelled': bg = Colors.red.shade50; fg = Colors.red.shade700; break;
      default: bg = Colors.grey.shade100; fg = Colors.grey.shade600;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

// ---------------------------------------------------------------------------
// NEW RETURN DIALOG — Premium SaaS Design with Tab (Invoice / Open Return)
// ---------------------------------------------------------------------------
class _NewReturnDialog extends StatefulWidget {
  final int? dssId;
  final VoidCallback onReturnProcessed;
  const _NewReturnDialog({required this.dssId, required this.onReturnProcessed});

  @override
  State<_NewReturnDialog> createState() => _NewReturnDialogState();
}

class _NewReturnDialogState extends State<_NewReturnDialog> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Shared
  String _selectedMode = 'Cash Refund';
  String _selectedReason = 'Damaged / Expired';
  static const _modes = ['Cash Refund', 'Store Credit', 'Original Payment Method'];
  static const _reasons = ['Damaged / Expired', 'Wrong Medicine Dispensed', 'Customer Changed Mind', 'Other'];

  // ── Invoice Return ────────────────────────────────────────────────────────
  bool _isLoadingSales = true;
  List<Sale> _allSales = [];
  Sale? _selectedSale;
  final TextEditingController _invoiceCtrl = TextEditingController();

  // ── Open Return ───────────────────────────────────────────────────────────
  bool _isLoadingOpenData = true;
  List<Product> _allProducts = [];
  List<Customer> _allCustomers = [];
  Customer? _selectedCustomer;
  final List<_OpenReturnItem> _openItems = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final sales = await DatabaseHelper.instance.getAllSales();
    final products = await DatabaseHelper.instance.getAllProducts();
    final customers = await DatabaseHelper.instance.getCustomers();
    if (!mounted) return;
    setState(() {
      _allSales = sales;
      _allProducts = products;
      _allCustomers = customers;
      _isLoadingSales = false;
      _isLoadingOpenData = false;
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _invoiceCtrl.dispose();
    super.dispose();
  }

  // ── Invoice Return: proceed to process dialog ─────────────────────────────
  Future<void> _proceedWithInvoice() async {
    if (_selectedSale == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an invoice first.'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoadingSales = true);
    final items = await DatabaseHelper.instance.getSaleItems(_selectedSale!.id!);
    if (!mounted) return;
    setState(() => _isLoadingSales = false);
    Navigator.pop(context);
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _ProcessReturnDialog(
        sale: _selectedSale!,
        items: items,
        dssId: widget.dssId ?? 0,
        mode: _selectedMode,
        reason: _selectedReason,
        onProcessed: widget.onReturnProcessed,
      ),
    );
  }

  // ── Open Return: submit directly ──────────────────────────────────────────
  double get _openTotal => _openItems.fold(0, (s, i) => s + i.lineTotal);

  Future<void> _submitOpenReturn() async {
    if (_openItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one item.'), backgroundColor: Colors.red));
      return;
    }

    final returnItems = _openItems.map((i) => SalesReturnItem(
      productId: i.product.id!,
      productName: i.product.name,
      quantityReturned: i.qty.toDouble(),
      price: i.product.sellPrice * (1 - i.discount / 100),
      total: i.lineTotal,
    )).toList();

    final cashRefund = _selectedMode == 'Cash Refund' ? _openTotal : 0.0;
    final credit = _selectedMode == 'Store Credit' ? _openTotal : 0.0;

    final returnObj = SalesReturn(
      dssId: widget.dssId ?? 0,
      date: DateTime.now(),
      invoiceNumber: 'OPEN-${DateTime.now().millisecondsSinceEpoch}',
      customerName: _selectedCustomer?.name,
      mode: _selectedMode,
      reason: _selectedReason,
      totalRefund: _openTotal,
      cashRefunded: cashRefund,
      creditIssued: credit,
      status: 'Posted',
      items: returnItems,
    );

    await DatabaseHelper.instance.insertSalesReturn(returnObj);
    if (!mounted) return;
    Navigator.pop(context);
    widget.onReturnProcessed();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open return processed successfully!'), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 620,
        constraints: const BoxConstraints(maxHeight: 720),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.13), blurRadius: 40, offset: const Offset(0, 16))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Gradient Header ────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 24, 20, 0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A3356), Color(0xFF0F4C81), Color(0xFF1565C0)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                        ),
                        child: const Icon(Icons.assignment_return_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('New Return', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                            Text('Process an invoice-based or open return', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.7), size: 20)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Tab bar inside header
                  TabBar(
                    controller: _tabCtrl,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.55),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    indicator: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: '  Invoice Return  '),
                      Tab(text: '  Open Return  '),
                    ],
                  ),
                ],
              ),
            ),

            // ── Tab Body ──────────────────────────────────────────────────
            Flexible(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildInvoiceTab(),
                  _buildOpenTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Invoice Return ─────────────────────────────────────────────────
  Widget _buildInvoiceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invoice Autocomplete
          _SectionLabel('Select Invoice'),
          const SizedBox(height: 8),
          _isLoadingSales
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              : Autocomplete<Sale>(
                  optionsBuilder: (TextEditingValue v) {
                    if (v.text.isEmpty) return _allSales;
                    final q = v.text.toLowerCase();
                    return _allSales.where((s) =>
                        s.invoiceNumber.toLowerCase().contains(q) ||
                        (s.customerName ?? '').toLowerCase().contains(q));
                  },
                  displayStringForOption: (Sale s) => s.invoiceNumber,
                  onSelected: (Sale s) => setState(() { _selectedSale = s; _invoiceCtrl.text = s.invoiceNumber; }),
                  fieldViewBuilder: (ctx, ctrl, fn, submit) {
                    return TextField(
                      controller: ctrl,
                      focusNode: fn,
                      decoration: InputDecoration(
                        hintText: 'Search by invoice number or customer...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      ),
                      onChanged: (val) { if (_selectedSale?.invoiceNumber != val) setState(() => _selectedSale = null); },
                    );
                  },
                  optionsViewBuilder: (ctx, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        shadowColor: Colors.black.withValues(alpha: 0.12),
                        child: Container(
                          width: 564,
                          constraints: const BoxConstraints(maxHeight: 220),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(6),
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (ctx, i) {
                              final s = options.elementAt(i);
                              final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                              final date = DateTime.parse(s.date);
                              final dateStr = '${date.day} ${months[date.month-1]} ${date.year}';
                              return InkWell(
                                onTap: () => onSelected(s),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: const Color(0xFFEBF3FB), borderRadius: BorderRadius.circular(6)),
                                        child: Text(s.invoiceNumber, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(s.customerName ?? 'Walk-in', style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
                                      Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                                      const SizedBox(width: 12),
                                      Text('Rs. ${s.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B))),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),

          // Selected invoice preview
          if (_selectedSale != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFD9F5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, color: _kPrimary, size: 18),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_selectedSale!.invoiceNumber} • ${_selectedSale!.customerName ?? 'Walk-in'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
                      const SizedBox(height: 2),
                      Text('Total: Rs. ${_selectedSale!.total.toStringAsFixed(0)} • ${_selectedSale!.paymentMethod}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                    child: Text('Selected', style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('Refund Mode'),
                  const SizedBox(height: 8),
                  _StyledDropdown<String>(
                    value: _selectedMode,
                    items: _modes,
                    onChanged: (v) => setState(() => _selectedMode = v!),
                  ),
                ],
              )),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('Reason'),
                  const SizedBox(height: 8),
                  _StyledDropdown<String>(
                    value: _selectedReason,
                    items: _reasons,
                    onChanged: (v) => setState(() => _selectedReason = v!),
                  ),
                ],
              )),
            ],
          ),

          const SizedBox(height: 28),
          _buildFooterRow(
            onPrimary: _isLoadingSales ? null : _proceedWithInvoice,
            primaryLabel: 'Find Invoice & Continue',
            primaryIcon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Open Return ────────────────────────────────────────────────────
  Widget _buildOpenTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer (optional)
          _SectionLabel('Customer (Optional)'),
          const SizedBox(height: 8),
          _isLoadingOpenData
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              : DropdownButtonFormField<Customer?>(
                  initialValue: _selectedCustomer,
                  isExpanded: true,
                  onChanged: (v) => setState(() => _selectedCustomer = v),
                  items: [
                    const DropdownMenuItem<Customer?>(value: null, child: Text('Walk-in Customer', style: TextStyle(fontSize: 13))),
                    ..._allCustomers.map((c) => DropdownMenuItem<Customer?>(value: c, child: Text(c.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))),
                  ],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    prefixIcon: const Icon(Icons.person_outline, size: 18),
                  ),
                ),

          const SizedBox(height: 20),

          // Add product row
          _SectionLabel('Products to Return'),
          const SizedBox(height: 8),
          _AddProductRow(
            products: _allProducts,
            onAdd: (item) => setState(() => _openItems.add(item)),
          ),

          // Items list
          if (_openItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                    child: Row(
                      children: [
                        Expanded(flex: 4, child: Text('PRODUCT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5))),
                        Expanded(flex: 2, child: Text('QTY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5))),
                        Expanded(flex: 2, child: Text('DISC %', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5))),
                        Expanded(flex: 2, child: Text('TOTAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5))),
                        const SizedBox(width: 36),
                      ],
                    ),
                  ),
                  ..._openItems.asMap().entries.map((e) {
                    final idx = e.key;
                    final item = e.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
                      child: Row(
                        children: [
                          Expanded(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                            Text('Rs. ${item.product.sellPrice.toStringAsFixed(0)}/unit', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                          ])),
                          Expanded(flex: 2, child: Text('×${item.qty}', style: const TextStyle(fontSize: 13))),
                          Expanded(flex: 2, child: Text('${item.discount}%', style: const TextStyle(fontSize: 13))),
                          Expanded(flex: 2, child: Text('Rs. ${item.lineTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade300, size: 18),
                            onPressed: () => setState(() => _openItems.removeAt(idx)),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('Refund Mode'),
                  const SizedBox(height: 8),
                  _StyledDropdown<String>(value: _selectedMode, items: _modes, onChanged: (v) => setState(() => _selectedMode = v!)),
                ],
              )),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('Reason'),
                  const SizedBox(height: 8),
                  _StyledDropdown<String>(value: _selectedReason, items: _reasons, onChanged: (v) => setState(() => _selectedReason = v!)),
                ],
              )),
            ],
          ),

          const SizedBox(height: 28),
          _buildFooterRow(
            onPrimary: _openItems.isEmpty ? null : _submitOpenReturn,
            primaryLabel: 'Submit Return  •  Rs. ${_openTotal.toStringAsFixed(0)}',
            primaryIcon: Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterRow({VoidCallback? onPrimary, required String primaryLabel, required IconData primaryIcon}) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: Colors.grey.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: onPrimary != null
                  ? const LinearGradient(colors: [Color(0xFF0F4C81), Color(0xFF1565C0)])
                  : LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade300]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: onPrimary != null
                  ? [BoxShadow(color: const Color(0xFF0F4C81).withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]
                  : [],
            ),
            child: ElevatedButton.icon(
              onPressed: onPrimary,
              icon: Icon(primaryIcon, size: 18),
              label: Text(primaryLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// OPEN RETURN ITEM model (in-memory only)
// ---------------------------------------------------------------------------
class _OpenReturnItem {
  final Product product;
  final int qty;
  final double discount;

  _OpenReturnItem({required this.product, required this.qty, required this.discount});

  double get lineTotal => product.sellPrice * qty * (1 - discount / 100);
}

// ---------------------------------------------------------------------------
// ADD PRODUCT ROW WIDGET (for Open Return)
// ---------------------------------------------------------------------------
class _AddProductRow extends StatefulWidget {
  final List<Product> products;
  final void Function(_OpenReturnItem) onAdd;
  const _AddProductRow({required this.products, required this.onAdd});

  @override
  State<_AddProductRow> createState() => _AddProductRowState();
}

class _AddProductRowState extends State<_AddProductRow> {
  Product? _product;
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');
  final TextEditingController _discCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _discCtrl.dispose();
    super.dispose();
  }

  void _add() {
    if (_product == null) return;
    final qty = int.tryParse(_qtyCtrl.text) ?? 1;
    final disc = double.tryParse(_discCtrl.text) ?? 0;
    if (qty <= 0) return;
    widget.onAdd(_OpenReturnItem(product: _product!, qty: qty, discount: disc));
    setState(() { _product = null; _qtyCtrl.text = '1'; _discCtrl.text = '0'; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Product autocomplete
          Expanded(
            flex: 4,
            child: Autocomplete<Product>(
              optionsBuilder: (v) {
                if (v.text.isEmpty) return widget.products;
                final q = v.text.toLowerCase();
                return widget.products.where((p) => p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q));
              },
              displayStringForOption: (p) => p.name,
              onSelected: (p) => setState(() => _product = p),
              fieldViewBuilder: (ctx, ctrl, fn, submit) {
                return TextField(
                  controller: ctrl,
                  focusNode: fn,
                  decoration: InputDecoration(
                    labelText: 'Product',
                    labelStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                );
              },
              optionsViewBuilder: (ctx, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 180, maxWidth: 280),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(4),
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (ctx, i) {
                          final p = options.elementAt(i);
                          return InkWell(
                            onTap: () => onSelected(p),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                Text('Rs. ${p.sellPrice.toStringAsFixed(0)} • Stock: ${p.stock.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          // Qty
          SizedBox(
            width: 70,
            child: TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Qty',
                labelStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Discount
          SizedBox(
            width: 80,
            child: TextField(
              controller: _discCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Disc %',
                labelStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Add button
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0F4C81), Color(0xFF1565C0)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              onPressed: _product != null ? _add : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Icon(Icons.add, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SHARED STYLED HELPERS
// ---------------------------------------------------------------------------
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B)));
}

class _StyledDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final void Function(T?) onChanged;
  const _StyledDropdown({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      onChanged: onChanged,
      items: items.map((m) => DropdownMenuItem<T>(value: m, child: Text(m.toString(), style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PROCESS RETURN DIALOG (premium redesign)
// ---------------------------------------------------------------------------
class _ProcessReturnDialog extends StatefulWidget {
  final Sale sale;
  final List<SaleItem> items;
  final int dssId;
  final String mode;
  final String reason;
  final VoidCallback onProcessed;
  const _ProcessReturnDialog({required this.sale, required this.items, required this.dssId, required this.mode, required this.reason, required this.onProcessed});

  @override
  State<_ProcessReturnDialog> createState() => _ProcessReturnDialogState();
}

class _ProcessReturnDialogState extends State<_ProcessReturnDialog> {
  final Map<int, double> _returnQty = {};
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    for (var item in widget.items) { _returnQty[item.id!] = 0; }
  }

  double get _total => widget.items.fold(0, (s, i) => s + (_returnQty[i.id!] ?? 0) * i.price);

  Future<void> _process() async {
    if (_total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one item to return.'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isProcessing = true);

    final returnItems = widget.items
        .where((i) => (_returnQty[i.id!] ?? 0) > 0)
        .map((i) => SalesReturnItem(productId: i.productId, productName: i.productName, quantityReturned: _returnQty[i.id!]!, price: i.price, total: _returnQty[i.id!]! * i.price))
        .toList();

    final ret = SalesReturn(
      dssId: widget.dssId,
      date: DateTime.now(),
      invoiceNumber: widget.sale.invoiceNumber,
      customerName: widget.sale.customerName,
      mode: widget.mode,
      reason: widget.reason,
      totalRefund: _total,
      cashRefunded: widget.mode == 'Cash Refund' ? _total : 0,
      creditIssued: widget.mode == 'Store Credit' ? _total : 0,
      status: 'Posted',
      items: returnItems,
    );

    await DatabaseHelper.instance.insertSalesReturn(ret);
    if (!mounted) return;
    setState(() => _isProcessing = false);
    Navigator.pop(context);
    widget.onProcessed();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return processed successfully!'), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 680),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.13), blurRadius: 40, offset: const Offset(0, 16))],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(28, 24, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green.shade900, Colors.green.shade700, Colors.green.shade500],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Process Return — ${widget.sale.invoiceNumber}', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text('${widget.sale.customerName ?? 'Walk-in'} • ${widget.mode}', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                    ],
                  )),
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.75))),
                ],
              ),
            ),

            // Items table
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select items and quantities to return', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B))),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                            child: Row(
                              children: [
                                Expanded(flex: 4, child: Text('ITEM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5))),
                                Expanded(flex: 2, child: Text('PRICE/UNIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5))),
                                Expanded(flex: 2, child: Text('PURCHASED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5))),
                                Expanded(flex: 3, child: Text('RETURN QTY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5))),
                                Expanded(flex: 2, child: Text('REFUND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5))),
                              ],
                            ),
                          ),
                          ...widget.items.map((item) {
                            final qty = _returnQty[item.id!] ?? 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
                              child: Row(
                                children: [
                                  Expanded(flex: 4, child: Text(item.productName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                                  Expanded(flex: 2, child: Text('Rs. ${item.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13))),
                                  Expanded(flex: 2, child: Text(item.quantity.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        _QtyBtn(icon: Icons.remove, onTap: qty > 0 ? () => setState(() => _returnQty[item.id!] = qty - 1) : null),
                                        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(qty.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                                        _QtyBtn(icon: Icons.add, onTap: qty < item.quantity ? () => setState(() => _returnQty[item.id!] = qty + 1) : null),
                                      ],
                                    ),
                                  ),
                                  Expanded(flex: 2, child: Text('Rs. ${(qty * item.price).toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)))),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Refund', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      Text('Rs. ${_total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _kPrimary)),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13), foregroundColor: Colors.grey.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200))),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: _total > 0
                          ? LinearGradient(colors: [Colors.green.shade700, Colors.green.shade500])
                          : LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade300]),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _total > 0 ? [BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing || _total <= 0 ? null : _process,
                      icon: _isProcessing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text('Confirm Return', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: onTap != null ? const Color(0xFFEBF3FB) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: onTap != null ? _kPrimary : Colors.grey.shade300),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// VIEW RETURN DIALOG
// ---------------------------------------------------------------------------
class _ViewReturnDialog extends StatefulWidget {
  final SalesReturn salesReturn;
  const _ViewReturnDialog({required this.salesReturn});

  @override
  State<_ViewReturnDialog> createState() => _ViewReturnDialogState();
}

class _ViewReturnDialogState extends State<_ViewReturnDialog> {
  List<SalesReturnItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await DatabaseHelper.instance.getReturnItems(widget.salesReturn.id!);
    if (!mounted) return;
    setState(() { _items = items; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.salesReturn;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = '${r.date.day} ${months[r.date.month - 1]} ${r.date.year}';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 640,
        constraints: const BoxConstraints(maxHeight: 680),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.13), blurRadius: 40, offset: const Offset(0, 16))],
        ),
        child: Column(
          children: [
            // ── Gradient Header ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 24, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A3356), Color(0xFF0F4C81), Color(0xFF1565C0)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RET-${r.id}', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                        const SizedBox(height: 3),
                        Text('${r.invoiceNumber}  •  $dateStr', style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 13)),
                        const SizedBox(height: 10),
                        // Meta chips row
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _MetaChip(icon: Icons.person_outline, label: r.customerName ?? 'Walk-in'),
                            _MetaChip(icon: Icons.payment_outlined, label: r.mode),
                            _MetaChip(icon: Icons.help_outline_rounded, label: r.reason),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.75), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary cards
                    Row(
                      children: [
                        _SummaryTile(label: 'Total Refund', value: 'Rs. ${r.totalRefund.toStringAsFixed(0)}', color: const Color(0xFF0F4C81)),
                        const SizedBox(width: 12),
                        _SummaryTile(label: 'Cash Refunded', value: 'Rs. ${r.cashRefunded.toStringAsFixed(0)}', color: Colors.green.shade700),
                        const SizedBox(width: 12),
                        _SummaryTile(label: 'Store Credit', value: 'Rs. ${r.creditIssued.toStringAsFixed(0)}', color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        _SummaryTile(label: 'Status', value: r.status, color: r.status == 'Posted' ? Colors.green.shade700 : Colors.orange.shade700, badge: true),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Items table
                    const Text('Returned Items', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                      child: _loading
                          ? const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                          : Column(
                              children: [
                                // Header
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 4, child: Text('PRODUCT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5))),
                                      Expanded(flex: 2, child: Text('QTY RETURNED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5))),
                                      Expanded(flex: 2, child: Text('UNIT PRICE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5))),
                                      Expanded(flex: 2, child: Text('REFUND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5))),
                                    ],
                                  ),
                                ),
                                if (_items.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Center(child: Text('No item details available', style: TextStyle(color: Colors.grey.shade400, fontSize: 13))),
                                  ),
                                ..._items.asMap().entries.map((e) {
                                  final idx = e.key;
                                  final item = e.value;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                                    decoration: BoxDecoration(
                                      color: idx.isEven ? Colors.white : Colors.grey.shade50,
                                      border: Border(top: BorderSide(color: Colors.grey.shade100)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 4, child: Row(children: [
                                          Container(
                                            width: 7, height: 7,
                                            margin: const EdgeInsets.only(right: 10),
                                            decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.4), shape: BoxShape.circle),
                                          ),
                                          Expanded(child: Text(item.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                                        ])),
                                        Expanded(flex: 2, child: Text(item.quantityReturned.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
                                        Expanded(flex: 2, child: Text('Rs. ${item.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13))),
                                        Expanded(flex: 2, child: Text('Rs. ${item.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)))),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer ────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0F4C81), Color(0xFF1565C0)]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: const Color(0xFF0F4C81).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DELETE RETURN DIALOG
// ---------------------------------------------------------------------------
class _DeleteReturnDialog extends StatefulWidget {
  final SalesReturn salesReturn;
  final VoidCallback onDeleted;
  const _DeleteReturnDialog({required this.salesReturn, required this.onDeleted});

  @override
  State<_DeleteReturnDialog> createState() => _DeleteReturnDialogState();
}

class _DeleteReturnDialogState extends State<_DeleteReturnDialog> {
  bool _isDeleting = false;

  Future<void> _confirmDelete() async {
    setState(() => _isDeleting = true);
    await DatabaseHelper.instance.deleteSalesReturn(widget.salesReturn.id!);
    if (!mounted) return;
    Navigator.pop(context);
    widget.onDeleted();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('RET-${widget.salesReturn.id} deleted and stock restored.'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.salesReturn;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 440,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.13), blurRadius: 40, offset: const Offset(0, 16))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Red Gradient Header ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 24, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.red.shade900, Colors.red.shade700, Colors.red.shade500],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Delete Return', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                        const SizedBox(height: 4),
                        Text('RET-${r.id}  •  ${r.invoiceNumber}', style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isDeleting ? null : () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.75), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
              child: Column(
                children: [
                  // Warning card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This action cannot be undone. Deleting this return will:\n\n• Remove the return record permanently\n• Reverse the stock restoration for all returned items',
                            style: TextStyle(fontSize: 13, color: Colors.red.shade800, height: 1.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Return summary info card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Customer', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(r.customerName ?? 'Walk-in', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ])),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Refund Amount', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('Rs. ${r.totalRefund.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red.shade700)),
                        ])),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Mode', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(r.mode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isDeleting ? null : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: Colors.grey.shade600,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.red.shade700, Colors.red.shade500]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _isDeleting ? null : _confirmDelete,
                            icon: _isDeleting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.delete_forever_rounded, size: 18),
                            label: Text(_isDeleting ? 'Deleting...' : 'Yes, Delete Return', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// VIEW DIALOG HELPERS
// ---------------------------------------------------------------------------
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool badge;
  const _SummaryTile({required this.label, required this.value, required this.color, this.badge = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            badge
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
                  )
                : Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.3)),
          ],
        ),
      ),
    );
  }
}

