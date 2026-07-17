import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/executive_header.dart';
import '../models/product.dart';
import '../models/purchase_order.dart';
import '../models/supplier.dart';
import '../services/database_helper.dart';
import '../utils/app_feedback.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PURCHASE ORDERS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  static const Color _primary = Color(0xFF0F4C81);
  static const Color _accent = Color(0xFF1976D2);
  static const Color _bg = Color(0xFFF4F7F6);

  String _search = '';
  String _statusFilter = 'All';
  bool _loading = true;

  List<PurchaseOrder> _orders = [];

  final List<String> _statuses = [
    'All',
    'Pending',
    'Ordered',
    'Partially Received',
    'Received',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await DatabaseHelper.instance.getAllPurchaseOrders();
    if (mounted)
      setState(() {
        _orders = orders;
        _loading = false;
      });
  }

  List<PurchaseOrder> get _filtered => _orders.where((o) {
    final q = _search.toLowerCase();
    final matchSearch =
        q.isEmpty ||
        o.poNumber.toLowerCase().contains(q) ||
        o.supplier.toLowerCase().contains(q);
    final matchStatus = _statusFilter == 'All' || o.status == _statusFilter;
    return matchSearch && matchStatus;
  }).toList();

  int _count(String s) => _orders.where((o) => o.status == s).length;

  Future<void> _createOrder() async {
    final products = await DatabaseHelper.instance.getAllProducts();
    if (!mounted) return;
    final order = await showDialog<PurchaseOrder>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OrderFormDialog(products: products),
    );
    if (order != null) {
      final saved = await DatabaseHelper.instance.insertPurchaseOrder(order);
      setState(() => _orders.insert(0, saved));
      AppFeedback.show(
        context,
        'Purchase order ${saved.poNumber} created',
        type: AppFeedbackType.success,
      );
    }
  }

  Future<void> _editOrder(PurchaseOrder order) async {
    final products = await DatabaseHelper.instance.getAllProducts();
    if (!mounted) return;
    final updated = await showDialog<PurchaseOrder>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OrderFormDialog(products: products, existing: order),
    );
    if (updated != null) {
      await DatabaseHelper.instance.updatePurchaseOrder(updated);
      await _load();
      AppFeedback.show(context, 'Order updated', type: AppFeedbackType.success);
    }
  }

  Future<void> _postOrder(PurchaseOrder order) async {
    await DatabaseHelper.instance.receivePurchaseOrder(order);
    await _load();
    AppFeedback.show(
      context,
      'Order posted — stock updated successfully',
      type: AppFeedbackType.success,
    );
  }

  Future<void> _cancelOrder(PurchaseOrder order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel ${order.poNumber}?'),
        content: const Text(
          'This will mark the order as Cancelled. Stock will NOT be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.updateOrderStatus(order.id!, 'Cancelled');
      await _load();
      AppFeedback.show(context, 'Order cancelled', type: AppFeedbackType.info);
    }
  }

  void _viewOrder(PurchaseOrder order) {
    showDialog(
      context: context,
      builder: (_) => _OrderDetailDialog(
        order: order,
        onMarkReceived:
            order.status != 'Received' && order.status != 'Cancelled'
            ? () {
                Navigator.pop(context);
                _postOrder(order);
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: _bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ExecutiveHeader(
              title: 'Purchase Orders',
              subtitle:
                  'Create and manage stock purchases. Mark as Received to auto-update inventory.',
            ),
            const SizedBox(height: 20),

            // ── New Order button ────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _createOrder,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('New Purchase Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Filters ─────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: 'Search PO number or supplier...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _statusFilter,
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey.shade600,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A2E2B),
                          fontWeight: FontWeight.w500,
                        ),
                        onChanged: (v) => setState(() => _statusFilter = v!),
                        items: _statuses
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Status pills ────────────────────────────────────────────────
            Wrap(
              spacing: 10,
              children: [
                _Pill(
                  'Pending: ${_count("Pending")}',
                  Colors.grey.shade700,
                  Colors.grey.shade100,
                ),
                _Pill(
                  'Ordered: ${_count("Ordered")}',
                  _accent,
                  _accent.withValues(alpha: 0.1),
                ),
                _Pill(
                  'Partially Rcvd: ${_count("Partially Received")}',
                  Colors.orange.shade800,
                  Colors.orange.shade50,
                ),
                _Pill(
                  'Received: ${_count("Received")}',
                  Colors.green.shade700,
                  Colors.green.shade50,
                ),
                _Pill(
                  'Cancelled: ${_count("Cancelled")}',
                  Colors.red.shade700,
                  Colors.red.shade50,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Table ───────────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(64),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : filtered.isEmpty
                  ? const _EmptyState()
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: _hdr('PO Number')),
                                Expanded(flex: 3, child: _hdr('Supplier')),
                                Expanded(flex: 2, child: _hdr('Date')),
                                Expanded(flex: 2, child: _hdr('Amount')),
                                Expanded(flex: 2, child: _hdr('Status')),
                                const Expanded(flex: 2, child: SizedBox()),
                              ],
                            ),
                          ),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: Colors.grey.shade100),
                            itemBuilder: (_, i) {
                              final o = filtered[i];
                              return _OrderRow(
                                order: o,
                                onView: () => _viewOrder(o),
                                onEdit:
                                    (o.status == 'Pending' ||
                                        o.status == 'Ordered')
                                    ? () => _editOrder(o)
                                    : null,
                                onCancel:
                                    (o.status != 'Cancelled' &&
                                        o.status != 'Received')
                                    ? () => _cancelOrder(o)
                                    : null,
                                onReceive:
                                    (o.status != 'Received' &&
                                        o.status != 'Cancelled')
                                    ? () => _postOrder(o)
                                    : null,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hdr(String t) => Text(
    t,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade600,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER ROW
// ─────────────────────────────────────────────────────────────────────────────
class _OrderRow extends StatefulWidget {
  final PurchaseOrder order;
  final VoidCallback onView;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onReceive;

  const _OrderRow({
    required this.order,
    required this.onView,
    this.onEdit,
    this.onCancel,
    this.onReceive,
  });

  @override
  State<_OrderRow> createState() => _OrderRowState();
}

class _OrderRowState extends State<_OrderRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    final currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final o = widget.order;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hover ? Colors.grey.shade50 : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                o.poNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1A2E2B),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                o.supplier,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                fmt.format(o.orderDate),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                currency.format(o.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(flex: 2, child: _StatusBadge(status: o.status)),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.onReceive != null) ...[
                    _RowBtn(
                      icon: Icons.upload_rounded,
                      tooltip: 'Post',
                      color: Colors.green.shade600,
                      onTap: widget.onReceive,
                    ),
                    const SizedBox(width: 6),
                  ],
                  _RowBtn(
                    icon: Icons.visibility_outlined,
                    tooltip: 'View',
                    onTap: widget.onView,
                  ),
                  if (widget.onEdit != null) ...[
                    const SizedBox(width: 6),
                    _RowBtn(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit',
                      onTap: widget.onEdit,
                    ),
                  ],
                  if (widget.onCancel != null) ...[
                    const SizedBox(width: 6),
                    _RowBtn(
                      icon: Icons.cancel_outlined,
                      tooltip: 'Cancel',
                      color: Colors.red.shade600,
                      onTap: widget.onCancel,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color? color;
  final VoidCallback? onTap;

  const _RowBtn({
    required this.icon,
    required this.tooltip,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 18, color: color ?? Colors.grey.shade600),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE & PILL
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg) = switch (status) {
      'Pending' => (Colors.grey.shade700, Colors.grey.shade100),
      'Ordered' => (const Color(0xFF1976D2), const Color(0xFFE3F2FD)),
      'Partially Received' => (Colors.orange.shade800, Colors.orange.shade50),
      'Received' => (Colors.green.shade700, Colors.green.shade50),
      'Cancelled' => (Colors.red.shade700, Colors.red.shade50),
      _ => (Colors.grey.shade700, Colors.grey.shade100),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color fg, bg;
  const _Pill(this.label, this.fg, this.bg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(64),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No purchase orders yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2E2B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click "New Purchase Order" to get started.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER DETAIL DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _OrderDetailDialog extends StatelessWidget {
  final PurchaseOrder order;
  final VoidCallback? onMarkReceived;

  const _OrderDetailDialog({required this.order, this.onMarkReceived});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    final currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 640,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F4C81), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.poNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.supplier,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: order.status),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meta row
                    Row(
                      children: [
                        _Meta('Order Date', fmt.format(order.orderDate)),
                        const SizedBox(width: 24),
                        _Meta('Items', '${order.items.length}'),
                        const SizedBox(width: 24),
                        _Meta('Total', currency.format(order.totalAmount)),
                        if (order.balance > 0) ...[
                          const SizedBox(width: 24),
                          _Meta(
                            'Balance Due',
                            currency.format(order.balance),
                            color: Colors.red.shade600,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Items table
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 4, child: _th('Product')),
                                Expanded(flex: 2, child: _th('Unit')),
                                Expanded(flex: 1, child: _th('Qty')),
                                Expanded(flex: 2, child: _th('Price')),
                                Expanded(flex: 2, child: _th('Subtotal')),
                              ],
                            ),
                          ),
                          ...order.items.asMap().entries.map((e) {
                            final i = e.value;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.grey.shade100),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      i.productName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      i.unitPurchased,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${i.quantity.toInt()}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      currency.format(i.purchasePrice),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      currency.format(i.subtotal),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Totals
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _TotalRow(
                            'Subtotal',
                            currency.format(order.subtotal),
                          ),
                          if (order.discount > 0)
                            _TotalRow(
                              'Discount',
                              currency.format(order.discount),
                            ),
                          if (order.taxRate > 0)
                            _TotalRow(
                              'Tax (${order.taxRate}%)',
                              currency.format(order.totalTax),
                            ),
                          const Divider(height: 16),
                          _TotalRow(
                            'Total',
                            currency.format(order.totalAmount),
                            bold: true,
                          ),
                          if (order.paidAmount > 0)
                            _TotalRow(
                              'Paid',
                              currency.format(order.paidAmount),
                            ),
                          if (order.balance > 0)
                            _TotalRow(
                              'Balance Due',
                              currency.format(order.balance),
                              color: Colors.red.shade600,
                            ),
                        ],
                      ),
                    ),

                    if (order.notes?.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notes_rounded,
                              size: 16,
                              color: Color(0xFF0369A1),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                order.notes!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (onMarkReceived != null) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: onMarkReceived,
                        icon: const Icon(Icons.upload_rounded, size: 18),
                        label: const Text(
                          'Post Order',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _th(String t) => Text(
    t,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade600,
    ),
  );
}

class _Meta extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _Meta(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: color ?? const Color(0xFF1A2E2B),
        ),
      ),
    ],
  );
}

class _TotalRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? color;
  const _TotalRow(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? const Color(0xFF1A2E2B),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER FORM DIALOG  (Create / Edit)
// ─────────────────────────────────────────────────────────────────────────────
class _OrderFormDialog extends StatefulWidget {
  final List<Product> products;
  final PurchaseOrder? existing;

  const _OrderFormDialog({required this.products, this.existing});

  @override
  State<_OrderFormDialog> createState() => _OrderFormDialogState();
}

class _OrderFormDialogState extends State<_OrderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSupplier;
  final _taxCtrl = TextEditingController(text: '0');
  final _paidCtrl = TextEditingController(text: '0');
  final _invoiceDiscCtrl = TextEditingController(text: '0');

  List<Supplier> _suppliers = [];
  bool _loadingSuppliers = true;

  List<_ItemRow> _items = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final settings = await DatabaseHelper.instance.getAllSettings();
    if (mounted) {
      if (widget.existing != null) {
        final o = widget.existing!;
        _selectedSupplier = o.supplier;
        _taxCtrl.text = o.taxRate.toString();
        _paidCtrl.text = o.paidAmount.toString();
        _invoiceDiscCtrl.text = o.discount.toString();
        _items = o.items.map((i) {
          final prod = widget.products.firstWhere(
            (p) => p.id == i.productId,
            orElse: () => widget.products.first,
          );
          return _ItemRow(
            product: prod,
            unitPurchased: i.unitPurchased,
            quantity: i.quantity,
            purchasePrice: i.purchasePrice,
            sellingPrice: i.sellingPrice,
            expiryDate: i.expiryDate,
          );
        }).toList();
      } else {
        _taxCtrl.text = settings['tax_rate'] ?? '0';
        if (widget.products.isNotEmpty) {
          _addItem();
        }
      }
      setState(() {});
    }
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    final list = await DatabaseHelper.instance.getSuppliers();
    setState(() {
      _suppliers = list;
      _loadingSuppliers = false;
    });
  }

  @override
  void dispose() {
    _taxCtrl.dispose();
    _paidCtrl.dispose();
    _invoiceDiscCtrl.dispose();
    super.dispose();
  }

  void _addItem() {
    if (widget.products.isEmpty) return;
    final p = widget.products.first;
    setState(
      () => _items.add(
        _ItemRow(
          product: p,
          unitPurchased: p.packaging.isNotEmpty
              ? p.packaging.first.name
              : 'Unit',
          quantity: 1,
          purchasePrice: p.costPrice,
          sellingPrice: p.sellPrice,
          gst: p.gst,
        ),
      ),
    );
  }

  double get _subtotal => _items.fold(
    0.0,
    (s, i) => s + (i.quantity * i.purchasePrice * (1 + i.gst / 100)),
  );
  double get _invoiceDiscount => double.tryParse(_invoiceDiscCtrl.text) ?? 0;
  double get _tax =>
      (_subtotal - _invoiceDiscount) *
      (double.tryParse(_taxCtrl.text) ?? 0) /
      100;
  double get _total => (_subtotal - _invoiceDiscount) + _tax;
  double get _balance => _total - (double.tryParse(_paidCtrl.text) ?? 0);
  final _currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplier == null ||
        _selectedSupplier!.isEmpty ||
        _items.isEmpty)
      return;
    setState(() => _saving = true);

    final order = PurchaseOrder(
      id: widget.existing?.id,
      poNumber: widget.existing?.poNumber ?? '',
      supplier: _selectedSupplier!,
      orderDate: widget.existing?.orderDate ?? DateTime.now(),
      status: widget.existing?.status ?? 'Pending',
      notes: null,
      taxRate: double.tryParse(_taxCtrl.text) ?? 0,
      taxAmount: _tax,
      paidAmount: double.tryParse(_paidCtrl.text) ?? 0,
      discount: _invoiceDiscount,
      items: _items
          .map(
            (r) => PurchaseOrderItem(
              productId: r.product.id,
              productName: r.product.name,
              unitPurchased: r.unitPurchased,
              quantity: r.quantity,
              purchasePrice: r.purchasePrice,
              sellingPrice: r.sellingPrice,
              discount: 0.0,
              gst: r.gst,
              expiryDate: r.expiryDate,
            ),
          )
          .toList(),
    );

    Navigator.pop(context, order);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Dialog(
      backgroundColor: const Color(0xFFF5F7FA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 1000,
        constraints: const BoxConstraints(maxHeight: 860),
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4C81).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Color(0xFF0F4C81),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Purchase Order' : 'New Purchase Order',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2E2B),
                          ),
                        ),
                        Text(
                          isEdit
                              ? 'Modify the order details below.'
                              : 'Record a new stock purchase from a supplier.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────────────────────────
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            // Supplier card
                            _Card(
                              title: 'Purchase Details',
                              subtitle:
                                  'Enter supplier name and reference info.',
                              child: Column(
                                children: [
                                  _LabelField(
                                    label: 'Supplier Name *',
                                    child: _loadingSuppliers
                                        ? const CircularProgressIndicator()
                                        : DropdownMenu<String>(
                                            initialSelection:
                                                _suppliers.any(
                                                  (s) =>
                                                      s.companyName ==
                                                      _selectedSupplier,
                                                )
                                                ? _selectedSupplier
                                                : null,
                                            expandedInsets: EdgeInsets.zero,
                                            enableFilter: true,
                                            inputDecorationTheme:
                                                const InputDecorationTheme(
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 11,
                                                      ),
                                                  filled: true,
                                                  fillColor: Color(0xFFF9FAFB),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                          Radius.circular(8),
                                                        ),
                                                    borderSide: BorderSide(
                                                      color: Color(0xFFD1D5DB),
                                                    ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                              Radius.circular(
                                                                8,
                                                              ),
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: Color(
                                                            0xFFD1D5DB,
                                                          ),
                                                        ),
                                                      ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                              Radius.circular(
                                                                8,
                                                              ),
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: Color(
                                                            0xFF0F4C81,
                                                          ),
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                ),
                                            dropdownMenuEntries: _suppliers.map(
                                              (s) {
                                                return DropdownMenuEntry<
                                                  String
                                                >(
                                                  value: s.companyName,
                                                  label: s.companyName,
                                                );
                                              },
                                            ).toList(),
                                            onSelected: (val) {
                                              if (val != null) {
                                                setState(() {
                                                  _selectedSupplier = val;
                                                });
                                              }
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Line items card
                            _Card(
                              title: 'Line Items',
                              subtitle: 'Add each product being purchased.',
                              trailing: TextButton.icon(
                                onPressed: widget.products.isEmpty
                                    ? null
                                    : _addItem,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Item'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF0F4C81),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              child: _items.isEmpty
                                  ? Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          widget.products.isEmpty
                                              ? 'No products in inventory. Add products first.'
                                              : 'Click "+ Add Item" to begin.',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: _items.asMap().entries.map((e) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _ItemCard(
                                            key: ValueKey(e.key),
                                            row: e.value,
                                            products: widget.products,
                                            index: e.key,
                                            onRemove: () => setState(
                                              () => _items.removeAt(e.key),
                                            ),
                                            onChanged: () => setState(() {}),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Right column — summary
                      SizedBox(
                        width: 260,
                        child: Column(
                          children: [
                            _Card(
                              title: 'Order Summary',
                              child: Column(
                                children: [
                                  _SummaryField(
                                    label: 'Tax %',
                                    controller: _taxCtrl,
                                    onChanged: () => setState(() {}),
                                  ),
                                  const SizedBox(height: 10),
                                  _SummaryField(
                                    label: 'Discount (Rs.)',
                                    controller: _invoiceDiscCtrl,
                                    onChanged: () => setState(() {}),
                                  ),
                                  const SizedBox(height: 10),
                                  _SummaryField(
                                    label: 'Amount Paid (Rs.)',
                                    controller: _paidCtrl,
                                    onChanged: () => setState(() {}),
                                  ),
                                  const Divider(height: 24),
                                  _SumRow(
                                    'Subtotal',
                                    _currency.format(_subtotal),
                                  ),
                                  if (_invoiceDiscount > 0) ...[
                                    const SizedBox(height: 6),
                                    _SumRow(
                                      'Discount',
                                      _currency.format(_invoiceDiscount),
                                    ),
                                  ],
                                  if ((double.tryParse(_taxCtrl.text) ?? 0) >
                                      0) ...[
                                    const SizedBox(height: 6),
                                    _SumRow('Tax', _currency.format(_tax)),
                                  ],
                                  const SizedBox(height: 6),
                                  _SumRow(
                                    'Total',
                                    _currency.format(_total),
                                    bold: true,
                                  ),
                                  if (_balance > 0) ...[
                                    const SizedBox(height: 6),
                                    _SumRow(
                                      'Balance',
                                      _currency.format(_balance),
                                      color: Colors.red.shade600,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ), // Added closing for Flexible
            // ── Footer ─────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed:
                          (_selectedSupplier == null ||
                              _selectedSupplier!.isEmpty ||
                              _items.isEmpty ||
                              _saving)
                          ? null
                          : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4C81),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isEdit ? 'Save Changes' : 'Create Purchase Order',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
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

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF0F4C81), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    isDense: true,
  );
}

// ─── Mutable item state (not immutable since dialog mutates it) ──────────────
class _ItemRow {
  Product product;
  String unitPurchased;
  double quantity;
  double purchasePrice;
  double sellingPrice;
  double gst;
  DateTime? expiryDate;

  _ItemRow({
    required this.product,
    required this.unitPurchased,
    required this.quantity,
    required this.purchasePrice,
    required this.sellingPrice,
    this.gst = 0.0,
    this.expiryDate,
  });
}

class _ItemCard extends StatefulWidget {
  final _ItemRow row;
  final List<Product> products;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ItemCard({
    super.key,
    required this.row,
    required this.products,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _sellCtrl;
  late final TextEditingController _gstCtrl;
  late final TextEditingController _expiryCtrl;
  late double _baseSellPrice; // base selling price before GST

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: widget.row.quantity.toString());
    _priceCtrl = TextEditingController(
      text: widget.row.purchasePrice.toString(),
    );
    _baseSellPrice = widget.row.sellingPrice;
    _sellCtrl = TextEditingController(text: widget.row.sellingPrice.toString());
    _gstCtrl = TextEditingController(text: widget.row.gst.toString());
    _expiryCtrl = TextEditingController(
      text: widget.row.expiryDate != null
          ? DateFormat('MMM d, yyyy').format(widget.row.expiryDate!)
          : '',
    );
  }

  Future<void> _pickExpiry() async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.row.expiryDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        widget.row.expiryDate = date;
        _expiryCtrl.text = DateFormat('MMM d, yyyy').format(date);
      });
      widget.onChanged();
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _sellCtrl.dispose();
    _gstCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  List<String> get _units {
    final pkg = widget.row.product.packaging;
    if (pkg.isNotEmpty) {
      final box = pkg.where((u) => u.name.toLowerCase() == 'box').toList();
      if (box.isNotEmpty) return [box.first.name];
      return [pkg.first.name];
    }
    return ['Unit'];
  }

  int get _calculatedBaseUnits {
    final p = widget.row.product;
    final unitName = widget.row.unitPurchased;
    final qty = widget.row.quantity;
    if (p.packaging.isEmpty) return qty.toInt();

    int multiplier = 1;
    bool found = false;
    for (var u in p.packaging) {
      if (u.name == unitName) found = true;
      if (found) multiplier *= u.contains;
    }
    return (qty * multiplier).toInt();
  }

  String get _baseUnitName {
    final p = widget.row.product;
    if (p.packaging.isEmpty) return 'Units';
    return p.packaging.last.name;
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.row;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item ${widget.index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF0F4C81),
                  ),
                ),
                InkWell(
                  onTap: widget.onRemove,
                  borderRadius: BorderRadius.circular(6),
                  child: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Row 1: Product dropdown + Unit dropdown + Qty
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: _LabelField(
                        label: 'Product',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Autocomplete<Product>(
                            initialValue: TextEditingValue(
                              text: r.product.name,
                            ),
                            displayStringForOption: (Product option) =>
                                option.name,
                            optionsBuilder:
                                (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return widget.products;
                                  }
                                  return widget.products.where((
                                    Product option,
                                  ) {
                                    return option.name.toLowerCase().contains(
                                          textEditingValue.text.toLowerCase(),
                                        ) ||
                                        option.sku.toLowerCase().contains(
                                          textEditingValue.text.toLowerCase(),
                                        );
                                  });
                                },
                            onSelected: (Product p) {
                              setState(() {
                                r.product = p;
                                r.unitPurchased = p.packaging.isNotEmpty
                                    ? p.packaging.first.name
                                    : 'Unit';

                                // Auto-fill prices only if product already has them set (previously purchased)
                                // If prices are 0 (new product), leave fields at 0 so user can enter them
                                final autoPurchasePrice = p.costPrice;
                                final autoSellPrice = p.sellPrice;
                                final autoGst = p.gst;

                                r.purchasePrice = autoPurchasePrice;
                                r.sellingPrice = autoSellPrice;
                                r.gst = autoGst;
                                _priceCtrl.text = autoPurchasePrice > 0
                                    ? autoPurchasePrice
                                          .toStringAsFixed(2)
                                          .replaceAll(
                                            RegExp(r'([.]*0+)(?!.*\d)'),
                                            '',
                                          )
                                    : '0';
                                _sellCtrl.text = autoSellPrice > 0
                                    ? autoSellPrice
                                          .toStringAsFixed(2)
                                          .replaceAll(
                                            RegExp(r'([.]*0+)(?!.*\d)'),
                                            '',
                                          )
                                    : '0';
                                _gstCtrl.text = autoGst > 0
                                    ? autoGst
                                          .toStringAsFixed(2)
                                          .replaceAll(
                                            RegExp(r'([.]*0+)(?!.*\d)'),
                                            '',
                                          )
                                    : '0';
                              });
                              widget.onChanged();
                            },
                            fieldViewBuilder:
                                (
                                  context,
                                  controller,
                                  focusNode,
                                  onFieldSubmitted,
                                ) {
                                  return TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1A2E2B),
                                    ),
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 11,
                                      ),
                                      border: InputBorder.none,
                                      hintText: 'Search product',
                                    ),
                                  );
                                },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(8),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxHeight: 250,
                                      maxWidth: 300,
                                    ),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (context, index) {
                                        final option = options.elementAt(index);
                                        return InkWell(
                                          onTap: () => onSelected(option),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Text(
                                              option.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
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
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _LabelField(
                        label: 'Unit',
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _units.contains(r.unitPurchased)
                                ? r.unitPurchased
                                : _units.first,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1A2E2B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LabelField(
                            label: 'Qty',
                            child: TextFormField(
                              controller: _qtyCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 11,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                isDense: true,
                              ),
                              onChanged: (v) {
                                setState(() {
                                  widget.row.quantity = double.tryParse(v) ?? 0;
                                });
                                widget.onChanged();
                              },
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if ((double.tryParse(v) ?? 0) <= 0)
                                  return 'Must be > 0';
                                return null;
                              },
                            ),
                          ),
                          if (widget.row.product.packaging.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 4),
                              child: Text(
                                '= $_calculatedBaseUnits $_baseUnitName',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Row 2: Purchase Price + Selling Price + Discount
                Row(
                  children: [
                    Expanded(
                      child: _LabelField(
                        label: 'Purchase Price (Rs.)',
                        child: TextFormField(
                          controller: _priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 11,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            r.purchasePrice = double.tryParse(v) ?? 0;
                            widget.onChanged();
                          },
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if ((double.tryParse(v) ?? 0) < 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LabelField(
                        label: 'Selling Price (Rs.)',
                        child: TextFormField(
                          controller: _sellCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 11,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            r.sellingPrice = double.tryParse(v) ?? 0;
                            widget.onChanged();
                          },
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if ((double.tryParse(v) ?? 0) < 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LabelField(
                        label: 'GST %',
                        child: TextFormField(
                          controller: _gstCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 11,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: true,
                            hintText: '0',
                            suffixText: '%',
                          ),
                          onChanged: (v) {
                            r.gst = double.tryParse(v) ?? 0;
                            widget.onChanged();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Show the GST-inclusive preview
                    Expanded(
                      child: _LabelField(
                        label: 'Final Sell Price',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            (r.sellingPrice * (1 + r.gst / 100))
                                .toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F4C81),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LabelField(
                        label: 'Expiry Date',
                        child: TextFormField(
                          controller: _expiryCtrl,
                          readOnly: true,
                          onTap: _pickExpiry,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 11,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: true,
                            hintText: 'Select Date',
                            suffixIcon: const Icon(
                              Icons.calendar_today,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  const _Card({
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2E2B),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LabelField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabelField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

class _SummaryField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _SummaryField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF0F4C81),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
          ),
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

class _SumRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? color;
  const _SumRow(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: color ?? const Color(0xFF1A2E2B),
        ),
      ),
    ],
  );
}
