import 'package:flutter/material.dart';
import '../widgets/executive_header.dart';

// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────

class SaleInvoice {
  final String invoiceId;
  final DateTime date;
  final String customer;
  final String warehouse;
  final double total;
  final double received;
  final double balance;
  final String method;
  final String status;

  SaleInvoice({
    required this.invoiceId,
    required this.date,
    required this.customer,
    required this.warehouse,
    required this.total,
    required this.received,
    required this.balance,
    required this.method,
    required this.status,
  });
}

// ─────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  static const Color _primary = Color(0xFF0F4C81);
  static const Color _pageBg = Color(0xFFF5F7FA);

  final TextEditingController _searchController = TextEditingController();
  final List<SaleInvoice> _invoices = [];
  bool _isSyncing = false;
  DateTime _reportingDate = DateTime.now();

  // ── Summary Stats ─────────────────────────
  double get _netSalesBooked => _invoices.fold(0, (s, i) => s + i.total);
  int get _invoiceCount => _invoices.length;
  double get _cashCollected => _invoices.fold(0, (s, i) => s + i.received);
  int get _fullySettled => _invoices.where((i) => i.balance == 0).length;
  double get _outstandingBalance => _invoices.fold(0, (s, i) => s + i.balance);
  int get _partialCount => _invoices.where((i) => i.balance > 0).length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _syncNow() {
    setState(() => _isSyncing = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isSyncing = false);
    });
  }

  void _showNewSaleDialog() {
    showDialog(
      context: context,
      builder: (_) => const _NewSaleDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const SizedBox(height: 20),
                  const ExecutiveHeader(title: 'Sales (POS)'),
                  const SizedBox(height: 24),
                  _buildSummaryCards(),
                  const SizedBox(height: 20),
                  _buildActionBar(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 0),
                  _buildInvoiceTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────
  Widget _buildTopBar() {
    final now = DateTime.now();
    final days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dayLabel = '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} — Desktop workspace';

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Breadcrumb
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text('Operations', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  const Text('Sales (POS)', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 2),
              Text(dayLabel, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            ],
          ),
          const Spacer(),

          // Search field
          Container(
            width: 280,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.only(left: 12, right: 4),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey.shade400, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search products, invoices, ledgers...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Open', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Notification bell
          Container(
            height: 38, width: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
              color: Colors.white,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.notifications_none, size: 20, color: Colors.grey.shade600),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 16),

          // Data synced pill
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade100),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text('Data synced', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Avatar + name pill
          Container(
            height: 42,
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(color: Color(0xFFE8EAF6), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Text('A', style: TextStyle(color: Color(0xFF5C6BC0), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alee', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.1)),
                    Text('Admin', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, height: 1.1)),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ── Summary Cards ─────────────────────────
  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.receipt_long_outlined,
            iconColor: _primary,
            iconBg: const Color(0xFFEBF3FB),
            label: 'Net sales booked',
            value: 'Rs. ${_netSalesBooked == 0 ? '0' : _netSalesBooked.toStringAsFixed(0)}',
            subLabel: '$_invoiceCount invoice${_invoiceCount == 1 ? '' : 's'} recorded',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            icon: Icons.payments_outlined,
            iconColor: const Color(0xFF16A34A),
            iconBg: const Color(0xFFE6F9F0),
            label: 'Cash collected',
            value: 'Rs. ${_cashCollected == 0 ? '0' : _cashCollected.toStringAsFixed(0)}',
            subLabel: '$_fullySettled fully settled',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
            label: 'Outstanding balance',
            value: 'Rs. ${_outstandingBalance == 0 ? '0' : _outstandingBalance.toStringAsFixed(0)}',
            subLabel: _partialCount == 0 ? 'No partial invoices' : '$_partialCount partial invoice${_partialCount == 1 ? '' : 's'}',
          ),
        ),
      ],
    );
  }

  // ── Action Bar ────────────────────────────
  Widget _buildActionBar() {
    return Row(
      children: [
        // Filter badges
        _FilterBadge(label: '${_invoiceCount} invoice${_invoiceCount == 1 ? '' : 's'}', icon: Icons.receipt_outlined, color: Colors.grey.shade700, bg: Colors.grey.shade100),
        const SizedBox(width: 8),
        _FilterBadge(label: '1 active DSS', icon: Icons.description_outlined, color: const Color(0xFF0F4C81), bg: const Color(0xFFEBF3FB)),
        const SizedBox(width: 8),
        _FilterBadge(label: 'No posted returns', icon: Icons.undo_outlined, color: const Color(0xFF16A34A), bg: const Color(0xFFE6F9F0)),
        const SizedBox(width: 8),
        _FilterBadge(label: '0% settled', icon: Icons.trending_up, color: const Color(0xFFD97706), bg: const Color(0xFFFEF3C7)),
        const Spacer(),
        // Action buttons
        _ActionButton(label: 'Export PDF', icon: Icons.picture_as_pdf_outlined, onTap: () {}),
        const SizedBox(width: 8),
        _ActionButton(label: 'Create DSS', icon: Icons.add_chart_outlined, onTap: () {}),
        const SizedBox(width: 8),
        _ActionButton(label: 'Close DSS', icon: Icons.lock_outline, onTap: () {}),
        const SizedBox(width: 10),
        // New Sale CTA
        ElevatedButton.icon(
          onPressed: _showNewSaleDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Sale', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  // ── Search Bar ────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by invoice number',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Invoice Table ─────────────────────────
  Widget _buildInvoiceTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border(
          left: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                _th('INVOICE', flex: 3),
                _th('DATE', flex: 3),
                _th('CUSTOMER', flex: 4),
                _th('WAREHOUSE', flex: 3),
                _th('TOTAL', flex: 2),
                _th('RECEIVED', flex: 2),
                _th('BALANCE', flex: 2),
                _th('METHOD', flex: 2),
                _th('STATUS', flex: 2),
                _th('ACTIONS', flex: 2, alignRight: true),
              ],
            ),
          ),
          // Table body
          _invoices.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _invoices.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (_, i) => _InvoiceRow(invoice: _invoices[i]),
                ),
        ],
      ),
    );
  }

  Widget _th(String text, {required int flex, bool alignRight = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade400,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(Icons.receipt_long_outlined, size: 36, color: Colors.grey.shade300),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String subLabel;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A2E2B))),
              const SizedBox(height: 2),
              Text(subLabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;

  const _FilterBadge({required this.label, required this.icon, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.onTap});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _hovering ? Colors.grey.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _hovering ? Colors.grey.shade300 : Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 7),
              Text(widget.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceRow extends StatefulWidget {
  final SaleInvoice invoice;

  const _InvoiceRow({required this.invoice});

  @override
  State<_InvoiceRow> createState() => _InvoiceRowState();
}

class _InvoiceRowState extends State<_InvoiceRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final d = widget.invoice.date;
    final dateStr = '${d.day} ${months[d.month - 1]} ${d.year}';

    Color statusColor;
    Color statusBg;
    switch (widget.invoice.status.toLowerCase()) {
      case 'paid':
        statusColor = const Color(0xFF16A34A);
        statusBg = const Color(0xFFE6F9F0);
        break;
      case 'partial':
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
        break;
      default:
        statusColor = Colors.grey.shade600;
        statusBg = Colors.grey.shade100;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hovering ? const Color(0xFFF5F7FA) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(widget.invoice.invoiceId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F4C81)))),
            Expanded(flex: 3, child: Text(dateStr, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
            Expanded(flex: 4, child: Text(widget.invoice.customer, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B)))),
            Expanded(flex: 3, child: Text(widget.invoice.warehouse, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
            Expanded(flex: 2, child: Text('Rs. ${widget.invoice.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            Expanded(flex: 2, child: Text('Rs. ${widget.invoice.received.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
            Expanded(flex: 2, child: Text('Rs. ${widget.invoice.balance.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, color: widget.invoice.balance > 0 ? const Color(0xFFD97706) : Colors.grey.shade600))),
            Expanded(flex: 2, child: Text(widget.invoice.method, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                child: Text(widget.invoice.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: _hovering ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RowIconBtn(icon: Icons.visibility_outlined, tooltip: 'View', onTap: () {}),
                      const SizedBox(width: 4),
                      _RowIconBtn(icon: Icons.print_outlined, tooltip: 'Print', onTap: () {}),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RowIconBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: Colors.grey.shade600),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NEW SALE DIALOG
// ─────────────────────────────────────────────

class _NewSaleDialog extends StatefulWidget {
  const _NewSaleDialog();

  @override
  State<_NewSaleDialog> createState() => _NewSaleDialogState();
}

class _NewSaleDialogState extends State<_NewSaleDialog> {
  static const Color _primary = Color(0xFF0F4C81);

  final List<_CartItem> _cart = [];
  String _selectedCustomer = '';
  String _paymentMethod = 'Cash';
  double _discountPercent = 0;

  double get _subtotal => _cart.fold(0, (s, i) => s + i.total);
  double get _discount => _subtotal * _discountPercent / 100;
  double get _total => _subtotal - _discount;

  void _addItem() {
    setState(() {
      _cart.add(_CartItem(name: 'Sample Medicine', price: 100, qty: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 700,
        height: 580,
        child: Column(
          children: [
            // Dialog header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  const Text('New Sale', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A2E2B))),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.grey.shade500,
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Customer + Payment Row
                    Row(
                      children: [
                        Expanded(child: _inputField('Customer', 'Search customer...', Icons.person_outline)),
                        const SizedBox(width: 16),
                        Expanded(child: _inputField('Warehouse', 'Select warehouse...', Icons.warehouse_outlined)),
                        const SizedBox(width: 16),
                        Expanded(child: _inputField('Payment Method', 'Cash', Icons.payment_outlined)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Medicine search
                    _inputField('Add Medicine', 'Search by name or batch...', Icons.medication_outlined),
                    const SizedBox(height: 16),
                    // Cart
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _cart.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_cart_outlined, size: 40, color: Colors.grey.shade300),
                                    const SizedBox(height: 10),
                                    Text('No items added yet', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: _cart.length,
                                itemBuilder: (_, i) => ListTile(
                                  title: Text(_cart[i].name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                  subtitle: Text('Rs. ${_cart[i].price.toStringAsFixed(0)} × ${_cart[i].qty}'),
                                  trailing: Text('Rs. ${_cart[i].total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, color: _primary)),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Item (Demo)'),
                    style: TextButton.styleFrom(foregroundColor: _primary),
                  ),
                  const Spacer(),
                  Text('Total: ', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                  Text('Rs. ${_total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _primary)),
                  const SizedBox(width: 20),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                    child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _cart.isEmpty ? null : () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                    child: const Text('Save & Print', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(String label, String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        TextFormField(
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, size: 17, color: Colors.grey.shade400),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: Color(0xFF0F4C81), width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _CartItem {
  final String name;
  final double price;
  int qty;

  _CartItem({required this.name, required this.price, required this.qty});

  double get total => price * qty;
}
