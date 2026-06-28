import 'package:flutter/material.dart';
import '../widgets/executive_header.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// MODELS
// ---------------------------------------------------------------------------
class PurchaseOrderItem {
  String medicineName;
  int quantity;
  double purchasePrice;
  double sellingPrice;
  double discount;
  DateTime? expiryDate;

  PurchaseOrderItem({
    required this.medicineName,
    required this.quantity,
    required this.purchasePrice,
    this.sellingPrice = 0.0,
    this.discount = 0.0,
    this.expiryDate,
  });

  double get subtotal => (quantity * purchasePrice) - discount;
}

class PurchaseOrder {
  final String id;
  final String poNumber;
  final String supplierName;
  final DateTime orderDate;
  final List<PurchaseOrderItem> items;
  String status; // 'Pending', 'Ordered', 'Partially Received', 'Received', 'Cancelled'
  final String? notes;
  final double taxRate;   // percentage e.g. 5 means 5%
  final double paidAmount;

  PurchaseOrder({
    required this.id,
    required this.poNumber,
    required this.supplierName,
    required this.orderDate,
    required this.items,
    required this.status,
    this.notes,
    this.taxRate = 0.0,
    this.paidAmount = 0.0,
  });

  double get subtotal    => items.fold(0, (sum, item) => sum + item.subtotal);
  double get taxAmount   => subtotal * taxRate / 100;
  double get totalAmount => subtotal + taxAmount;
  double get balanceDue  => totalAmount - paidAmount;
}

// ---------------------------------------------------------------------------
// MAIN SCREEN
// ---------------------------------------------------------------------------
class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  // Theme Tokens
  static const Color _primaryColor = Color(0xFF0F4C81);
  static const Color _accentColor = Color(0xFF1976D2);
  static const Color _backgroundColor = Color(0xFFF4F7F6);

  String _searchQuery = '';
  String _selectedSupplier = 'All Suppliers';
  String _selectedStatus = 'All';

  final List<String> _suppliers = ['All Suppliers', 'PharmaCorp', 'MediSupply Inc.', 'Global Health', 'Local Meds'];
  final List<String> _statuses = ['All', 'Pending', 'Ordered', 'Partially Received', 'Received', 'Cancelled'];
  final List<String> _dummyMedicines = ['Panadol 500mg', 'Amoxil 250mg', 'Brufen 400mg', 'Augmentin 625mg', 'Disprin'];

  // TODO: Replace local list with real-time Firestore stream from 'purchaseOrders' collection
  List<PurchaseOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _generateDummyData();
  }

  void _generateDummyData() {
    _orders = [
      PurchaseOrder(
        id: '1',
        poNumber: 'PO-1024',
        supplierName: 'PharmaCorp',
        orderDate: DateTime.now().subtract(const Duration(days: 2)),
        status: 'Pending',
        items: [
          PurchaseOrderItem(medicineName: 'Panadol 500mg', quantity: 100, purchasePrice: 15.0, sellingPrice: 20.0),
          PurchaseOrderItem(medicineName: 'Brufen 400mg', quantity: 50, purchasePrice: 20.0, sellingPrice: 25.0),
        ],
      ),
      PurchaseOrder(
        id: '2',
        poNumber: 'PO-1025',
        supplierName: 'MediSupply Inc.',
        orderDate: DateTime.now().subtract(const Duration(days: 5)),
        status: 'Received',
        items: [
          PurchaseOrderItem(medicineName: 'Amoxil 250mg', quantity: 200, purchasePrice: 45.0, sellingPrice: 55.0),
        ],
      ),
      PurchaseOrder(
        id: '3',
        poNumber: 'PO-1026',
        supplierName: 'Global Health',
        orderDate: DateTime.now().subtract(const Duration(days: 1)),
        status: 'Ordered',
        items: [
          PurchaseOrderItem(medicineName: 'Augmentin 625mg', quantity: 30, purchasePrice: 120.0, sellingPrice: 150.0),
        ],
      ),
      PurchaseOrder(
        id: '4',
        poNumber: 'PO-1027',
        supplierName: 'Local Meds',
        orderDate: DateTime.now().subtract(const Duration(days: 10)),
        status: 'Partially Received',
        items: [
          PurchaseOrderItem(medicineName: 'Disprin', quantity: 500, purchasePrice: 2.0, sellingPrice: 3.0),
        ],
      ),
      PurchaseOrder(
        id: '5',
        poNumber: 'PO-1028',
        supplierName: 'PharmaCorp',
        orderDate: DateTime.now().subtract(const Duration(days: 15)),
        status: 'Cancelled',
        items: [
          PurchaseOrderItem(medicineName: 'Panadol 500mg', quantity: 1000, purchasePrice: 14.5, sellingPrice: 18.0),
        ],
      ),
      PurchaseOrder(
        id: '6',
        poNumber: 'PO-1029',
        supplierName: 'MediSupply Inc.',
        orderDate: DateTime.now(),
        status: 'Pending',
        items: [
          PurchaseOrderItem(medicineName: 'Brufen 400mg', quantity: 100, purchasePrice: 19.5, sellingPrice: 25.0),
        ],
      ),
      PurchaseOrder(
        id: '7',
        poNumber: 'PO-1030',
        supplierName: 'Global Health',
        orderDate: DateTime.now().subtract(const Duration(days: 4)),
        status: 'Ordered',
        items: [
          PurchaseOrderItem(medicineName: 'Amoxil 250mg', quantity: 150, purchasePrice: 46.0, sellingPrice: 55.0),
        ],
      ),
      PurchaseOrder(
        id: '8',
        poNumber: 'PO-1031',
        supplierName: 'Local Meds',
        orderDate: DateTime.now().subtract(const Duration(days: 8)),
        status: 'Received',
        items: [
          PurchaseOrderItem(medicineName: 'Augmentin 625mg', quantity: 50, purchasePrice: 118.0, sellingPrice: 150.0),
        ],
      ),
    ];
  }

  List<PurchaseOrder> get _filteredOrders {
    return _orders.where((o) {
      final matchesSearch = _searchQuery.isEmpty ||
          o.poNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.supplierName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSupplier = _selectedSupplier == 'All Suppliers' || o.supplierName == _selectedSupplier;
      final matchesStatus = _selectedStatus == 'All' || o.status == _selectedStatus;
      return matchesSearch && matchesSupplier && matchesStatus;
    }).toList();
  }

  int _countStatus(String status) => _orders.where((o) => o.status == status).length;

  void _deleteOrder(PurchaseOrder order) {
    // TODO: On cancel, update status to 'Cancelled' in Firestore instead of deleting
    setState(() {
      order.status = 'Cancelled';
    });
    _showCustomSnackBar(context, 'Order cancelled successfully', isError: true);
  }

  void _markAsReceived(PurchaseOrder order) {
    // TODO: On "Mark as Received", update Firestore order status AND increment matching medicine quantities in 'medicines' collection (use a batch/transaction)
    setState(() {
      order.status = 'Received';
    });
    _showCustomSnackBar(context, 'Order marked as received');
  }

  void _saveNewOrder(PurchaseOrder newOrder) {
    // TODO: On create, write new document to Firestore 'purchaseOrders' collection
    setState(() {
      _orders.insert(0, newOrder);
    });
    _showCustomSnackBar(context, 'Purchase order created successfully');
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Executive Header ─────────────────────────────────────────────
            const ExecutiveHeader(title: 'Purchase Orders', subtitle: 'Manage orders placed with suppliers, track delivery status, and monitor pending stock.'),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showNewOrderDialog(context),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('New Purchase Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
            const SizedBox(height: 32),

            // ── Filters & Summary ────────────────────────────────────────
            Row(
              children: [
                // Search
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search PO number or supplier...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Supplier Filter
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSupplier,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF1A2E2B), fontWeight: FontWeight.w500),
                        onChanged: (val) => setState(() => _selectedSupplier = val!),
                        items: _suppliers.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Status Filter
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF1A2E2B), fontWeight: FontWeight.w500),
                        onChanged: (val) => setState(() => _selectedStatus = val!),
                        items: _statuses.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Status Pills ─────────────────────────────────────────────
            Row(
              children: [
                _StatusPill(label: 'Pending: ${_countStatus('Pending')}', color: Colors.grey.shade600, bgColor: Colors.grey.shade100),
                const SizedBox(width: 12),
                _StatusPill(label: 'Ordered: ${_countStatus('Ordered')}', color: _accentColor, bgColor: _accentColor.withValues(alpha: 0.1)),
                const SizedBox(width: 12),
                _StatusPill(label: 'Received: ${_countStatus('Received')}', color: Colors.green.shade700, bgColor: Colors.green.shade50),
              ],
            ),
            const SizedBox(height: 24),

            // ── Main Table Card ──────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: filtered.isEmpty
                  ? _EmptyState()
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text('PO Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600))),
                                Expanded(flex: 3, child: Text('Supplier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600))),
                                Expanded(flex: 2, child: Text('Order Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600))),
                                Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600))),
                                Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600))),
                                const Expanded(flex: 2, child: SizedBox.shrink()), // Actions
                              ],
                            ),
                          ),
                          // Table Rows
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                            itemBuilder: (context, index) {
                              final order = filtered[index];
                              return _OrderRow(
                                order: order,
                                onView: () => _showOrderDetailDialog(context, order),
                                onEdit: (order.status == 'Pending' || order.status == 'Ordered') ? () => _showEditOrderDialog(context, order) : null,
                                onCancel: (order.status != 'Cancelled' && order.status != 'Received') ? () => _confirmCancelOrder(context, order) : null,
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

  void _showNewOrderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _NewOrderDialog(
        suppliers: _suppliers.where((s) => s != 'All Suppliers').toList(),
        medicines: _dummyMedicines,
        onSave: (order) {
          _saveNewOrder(order);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showOrderDetailDialog(BuildContext context, PurchaseOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => _OrderDetailDialog(
        order: order,
        onMarkReceived: () {
          _markAsReceived(order);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _confirmCancelOrder(BuildContext context, PurchaseOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel ${order.poNumber}?'),
        content: const Text('Are you sure you want to cancel this purchase order? This action will mark it as Cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteOrder(order);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  void _showEditOrderDialog(BuildContext context, PurchaseOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => _EditOrderDialog(
        order: order,
        suppliers: _suppliers.where((s) => s != 'All Suppliers').toList(),
        medicines: _dummyMedicines,
        onSave: (updatedOrder) {
          setState(() {
            final idx = _orders.indexWhere((o) => o.id == updatedOrder.id);
            if (idx != -1) _orders[idx] = updatedOrder;
          });
          _showCustomSnackBar(context, 'Order updated successfully');
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WIDGETS
// ---------------------------------------------------------------------------

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _StatusPill({required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}


class _OrderRow extends StatefulWidget {
  final PurchaseOrder order;
  final VoidCallback onView;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  const _OrderRow({required this.order, required this.onView, this.onEdit, this.onCancel});

  @override
  State<_OrderRow> createState() => _OrderRowState();
}

class _OrderRowState extends State<_OrderRow> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: _isHovering ? Colors.grey.shade50 : Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                widget.order.poNumber,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A2E2B)),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                widget.order.supplierName,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                dateFormat.format(widget.order.orderDate),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                currencyFormat.format(widget.order.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A2E2B)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusBadge(status: widget.order.status),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _IconButton(icon: Icons.visibility_outlined, onTap: widget.onView, tooltip: 'View'),
                  const SizedBox(width: 8),
                  if (widget.onEdit != null) ...[
                    _IconButton(icon: Icons.edit_outlined, onTap: widget.onEdit, tooltip: 'Edit'),
                    const SizedBox(width: 8),
                  ],
                  if (widget.onCancel != null)
                    _IconButton(icon: Icons.cancel_outlined, onTap: widget.onCancel, tooltip: 'Cancel', color: Colors.red.shade600),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final Color? color;

  const _IconButton({required this.icon, this.onTap, required this.tooltip, this.color});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          hoverColor: (color ?? Colors.grey.shade600).withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 18,
              color: color ?? Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;

    switch (status) {
      case 'Pending':
        color = Colors.grey.shade700;
        bgColor = Colors.grey.shade100;
        break;
      case 'Ordered':
        color = const Color(0xFF1976D2);
        bgColor = const Color(0xFF1976D2).withValues(alpha: 0.1);
        break;
      case 'Partially Received':
        color = Colors.orange.shade800;
        bgColor = Colors.orange.shade50;
        break;
      case 'Received':
        color = Colors.green.shade700;
        bgColor = Colors.green.shade50;
        break;
      case 'Cancelled':
        color = Colors.red.shade700;
        bgColor = Colors.red.shade50;
        break;
      default:
        color = Colors.grey.shade700;
        bgColor = Colors.grey.shade100;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
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
              child: Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            const Text(
              'No purchase orders found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2E2B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DIALOGS
// ---------------------------------------------------------------------------

class _NewOrderDialog extends StatefulWidget {
  final List<String> suppliers;
  final List<String> medicines;
  final ValueChanged<PurchaseOrder> onSave;

  const _NewOrderDialog({
    required this.suppliers,
    required this.medicines,
    required this.onSave,
  });

  @override
  State<_NewOrderDialog> createState() => _NewOrderDialogState();
}

class _NewOrderDialogState extends State<_NewOrderDialog> {
  String? _selectedSupplier;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _taxController = TextEditingController(text: '0');
  final TextEditingController _paidController = TextEditingController(text: '0');
  final List<PurchaseOrderItem> _items = [];

  final _dateFormat = DateFormat('MMM d, yyyy');

  void _addItem() {
    setState(() {
      _items.add(PurchaseOrderItem(medicineName: widget.medicines.first, quantity: 1, purchasePrice: 0.0));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  double get _subtotal      => _items.fold(0.0, (sum, i) => sum + i.quantity * i.purchasePrice);
  double get _totalDiscount => _items.fold(0.0, (sum, i) => sum + i.discount);
  double get _taxRate       => double.tryParse(_taxController.text) ?? 0.0;
  double get _taxAmount     => (_subtotal - _totalDiscount) * _taxRate / 100;
  double get _total         => _subtotal - _totalDiscount + _taxAmount;
  double get _paidAmount    => double.tryParse(_paidController.text) ?? 0.0;
  double get _balanceDue    => _total - _paidAmount;

  @override
  Widget build(BuildContext context) {
    final canSave = _selectedSupplier != null && _items.isNotEmpty;
    final poNumber = 'PO-${10000 + DateTime.now().millisecondsSinceEpoch % 90000}';

    return Dialog(
      backgroundColor: const Color(0xFFF5F6FA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 980,
        constraints: const BoxConstraints(maxHeight: 860),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Dialog Header ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4C81).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0F4C81), size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New Purchase Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
                        SizedBox(height: 2),
                        Text('Record a new stock purchase from a supplier', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context), splashRadius: 20),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),

            // ── Body ──────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── LEFT COLUMN ──────────────────────────────────────
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Purchase Header Card
                          Container(
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
                                    const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Purchase Header', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
                                        SizedBox(height: 3),
                                        Text('Set the supplier and purchase reference details.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        border: Border.all(color: Colors.green.shade300),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(children: [
                                        Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                                        const SizedBox(width: 5),
                                        Text('Pending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                                      ]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('PO Number', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              border: Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(poNumber, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Supplier *', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: _selectedSupplier,
                                                isExpanded: true,
                                                hint: const Text('Select Supplier', style: TextStyle(fontSize: 14)),
                                                onChanged: (val) => setState(() => _selectedSupplier = val),
                                                items: widget.suppliers.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Line Items Card
                          Container(
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
                                    const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Line Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
                                        SizedBox(height: 3),
                                        Text('Add each medicine being purchased from supplier.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                    TextButton.icon(
                                      onPressed: _addItem,
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Add item'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFF0F4C81),
                                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_items.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('${_items.length} item${_items.length > 1 ? 's' : ''} added', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                  const SizedBox(height: 12),
                                ],
                                if (_items.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                                    ),
                                    child: Center(child: Text('No items yet. Click "+ Add item" to begin.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _items.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                                    itemBuilder: (ctx, index) {
                                      final item = _items[index];
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
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text('Item ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F4C81))),
                                                  InkWell(
                                                    onTap: () => _removeItem(index),
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Item fields
                                            Padding(
                                              padding: const EdgeInsets.all(14),
                                              child: Column(
                                                children: [
                                                  // Row 1: Medicine + Qty
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 3,
                                                        child: _FieldLabel(
                                                          label: 'Product',
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                                            child: DropdownButtonHideUnderline(
                                                              child: DropdownButton<String>(
                                                                value: item.medicineName,
                                                                isExpanded: true,
                                                                onChanged: (val) => setState(() => item.medicineName = val!),
                                                                items: widget.medicines.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        flex: 1,
                                                        child: _FieldLabel(
                                                          label: 'Qty',
                                                          child: TextFormField(
                                                            initialValue: item.quantity.toString(),
                                                            keyboardType: TextInputType.number,
                                                            style: const TextStyle(fontSize: 14),
                                                            decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                                                            onChanged: (val) => setState(() => item.quantity = int.tryParse(val) ?? 0),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  // Row 2: Purchase Price + Selling Price + Discount
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: _FieldLabel(
                                                          label: 'Purchase Price',
                                                          child: TextFormField(
                                                            initialValue: item.purchasePrice.toString(),
                                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                            style: const TextStyle(fontSize: 14),
                                                            decoration: InputDecoration(prefixText: 'Rs. ', contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                                                            onChanged: (val) => setState(() => item.purchasePrice = double.tryParse(val) ?? 0.0),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: _FieldLabel(
                                                          label: 'Selling Price',
                                                          child: TextFormField(
                                                            initialValue: item.sellingPrice.toString(),
                                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                            style: const TextStyle(fontSize: 14),
                                                            decoration: InputDecoration(prefixText: 'Rs. ', contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                                                            onChanged: (val) => setState(() => item.sellingPrice = double.tryParse(val) ?? 0.0),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: _FieldLabel(
                                                          label: 'Discount (Rs.)',
                                                          child: TextFormField(
                                                            initialValue: item.discount.toString(),
                                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                            style: const TextStyle(fontSize: 14),
                                                            decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                                                            onChanged: (val) => setState(() => item.discount = double.tryParse(val) ?? 0.0),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  // Row 3: Expiry + Subtotal
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 2,
                                                        child: _FieldLabel(
                                                          label: 'Expiry Date',
                                                          child: InkWell(
                                                            onTap: () async {
                                                              final date = await showDatePicker(
                                                                context: context,
                                                                initialDate: item.expiryDate ?? DateTime.now().add(const Duration(days: 365)),
                                                                firstDate: DateTime.now(),
                                                                lastDate: DateTime.now().add(const Duration(days: 3650)),
                                                              );
                                                              if (date != null) setState(() => item.expiryDate = date);
                                                            },
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                                                              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                                              child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  Text(
                                                                    item.expiryDate != null ? _dateFormat.format(item.expiryDate!) : 'Select date',
                                                                    style: TextStyle(fontSize: 14, color: item.expiryDate != null ? const Color(0xFF1A2E2B) : Colors.grey.shade500),
                                                                  ),
                                                                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade500),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        flex: 1,
                                                        child: _FieldLabel(
                                                          label: 'Subtotal',
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                                                            decoration: BoxDecoration(color: Colors.blue.shade50, border: Border.all(color: Colors.blue.shade100), borderRadius: BorderRadius.circular(8)),
                                                            child: Text(
                                                              'Rs. ${item.subtotal.toStringAsFixed(0)}',
                                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F4C81)),
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
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // ─── RIGHT COLUMN ─────────────────────────────────────
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Amounts Card
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Amounts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
                                const SizedBox(height: 3),
                                const Text('Live totals based on line items.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 18),

                                // Notes
                                Text('Notes (Optional)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextField(
                                    controller: _notesController,
                                    maxLines: 3,
                                    style: const TextStyle(fontSize: 14),
                                    decoration: const InputDecoration(
                                      hintText: 'Optional receiving notes...',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.all(12),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Tax Rate
                                Text('Tax Rate (%)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _taxController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    suffixText: '%',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    isDense: true,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),

                                const SizedBox(height: 12),

                                // Paid Amount
                                Text('Paid Amount', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _paidController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    prefixText: 'Rs. ',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    isDense: true,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),

                                const SizedBox(height: 20),
                                Divider(color: Colors.grey.shade200),
                                const SizedBox(height: 12),

                                // Summary rows
                                _SummaryRow(label: 'Subtotal', value: 'Rs. ${_subtotal.toStringAsFixed(0)}'),
                                const SizedBox(height: 6),
                                _SummaryRow(label: 'Total Discount', value: '- Rs. ${_totalDiscount.toStringAsFixed(0)}', valueColor: Colors.orange.shade700),
                                const SizedBox(height: 6),
                                _SummaryRow(label: 'Tax (${_taxRate.toStringAsFixed(1)}%)', value: '+ Rs. ${_taxAmount.toStringAsFixed(0)}', valueColor: Colors.blue.shade700),
                                const SizedBox(height: 12),
                                Divider(color: Colors.grey.shade200),
                                const SizedBox(height: 6),
                                _SummaryRow(label: 'Total', value: 'Rs. ${_total.toStringAsFixed(0)}', valueColor: const Color(0xFF1A2E2B)),
                                const SizedBox(height: 6),
                                _SummaryRow(label: 'Paid Amount', value: '- Rs. ${_paidAmount.toStringAsFixed(0)}', valueColor: Colors.green.shade700),
                                const SizedBox(height: 12),
                                Divider(color: Colors.grey.shade200),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Balance Due', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _balanceDue > 0 ? Colors.orange.shade800 : Colors.green.shade800)),
                                    Text(
                                      'Rs. ${_balanceDue.abs().toStringAsFixed(0)}',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _balanceDue > 0 ? Colors.orange.shade800 : Colors.green.shade800),
                                    ),
                                  ],
                                ),
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

            // ── Footer ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), foregroundColor: Colors.grey.shade700),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: canSave
                        ? () {
                            final newOrder = PurchaseOrder(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              poNumber: poNumber,
                              supplierName: _selectedSupplier!,
                              orderDate: DateTime.now(),
                              items: List.from(_items),
                              status: 'Pending',
                              notes: _notesController.text,
                              taxRate: _taxRate,
                              paidAmount: _paidAmount,
                            );
                            widget.onSave(newOrder);
                          }
                        : null,
                    icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                    label: const Text('Record Purchase', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C81),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
// EDIT ORDER DIALOG
// ---------------------------------------------------------------------------
class _EditOrderDialog extends StatefulWidget {
  final PurchaseOrder order;
  final List<String> suppliers;
  final List<String> medicines;
  final ValueChanged<PurchaseOrder> onSave;

  const _EditOrderDialog({
    required this.order,
    required this.suppliers,
    required this.medicines,
    required this.onSave,
  });

  @override
  State<_EditOrderDialog> createState() => _EditOrderDialogState();
}

class _EditOrderDialogState extends State<_EditOrderDialog> {
  late String _selectedSupplier;
  late TextEditingController _notesController;
  late TextEditingController _taxController;
  late TextEditingController _paidController;
  late List<PurchaseOrderItem> _items;
  late String _selectedStatus;

  static const _editableStatuses = ['Pending', 'Ordered'];

  @override
  void initState() {
    super.initState();
    _selectedSupplier = widget.order.supplierName;
    _notesController = TextEditingController(text: widget.order.notes ?? '');
    _taxController = TextEditingController(text: widget.order.taxRate.toString());
    _paidController = TextEditingController(text: widget.order.paidAmount.toString());
    _selectedStatus = widget.order.status;
    // Deep-copy items so edits don't mutate the original until save
    _items = widget.order.items
        .map((i) => PurchaseOrderItem(
              medicineName: i.medicineName,
              quantity: i.quantity,
              purchasePrice: i.purchasePrice,
              sellingPrice: i.sellingPrice,
              discount: i.discount,
              expiryDate: i.expiryDate,
            ))
        .toList();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _taxController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(PurchaseOrderItem(
          medicineName: widget.medicines.first, quantity: 1, purchasePrice: 0.0));
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  double get _subtotal      => _items.fold(0.0, (s, i) => s + i.quantity * i.purchasePrice);
  double get _totalDiscount => _items.fold(0.0, (s, i) => s + i.discount);
  double get _taxRate       => double.tryParse(_taxController.text) ?? 0.0;
  double get _taxAmount     => (_subtotal - _totalDiscount) * _taxRate / 100;
  double get _total         => _subtotal - _totalDiscount + _taxAmount;
  double get _paidAmount    => double.tryParse(_paidController.text) ?? 0.0;
  double get _balanceDue    => _total - _paidAmount;

  final _dateFormat = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final canSave = _items.isNotEmpty;

    return Dialog(
      backgroundColor: const Color(0xFFF5F6FA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 980,
        constraints: const BoxConstraints(maxHeight: 860),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Dialog Header ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4C81).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_note_outlined, color: Color(0xFF0F4C81), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Edit ${widget.order.poNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
                        const SizedBox(height: 2),
                        const Text('Modify order details and line items below', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context), splashRadius: 20),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),

            // ── Body ──────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── LEFT COLUMN ──────────────────────────────────────
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Purchase Header Card
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Purchase Header', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
                                        SizedBox(height: 3),
                                        Text('Edit the supplier and order status.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, border: Border.all(color: Colors.blue.shade300), borderRadius: BorderRadius.circular(20)),
                                      child: Row(children: [
                                        Icon(Icons.info_outline, size: 14, color: Colors.blue.shade600),
                                        const SizedBox(width: 5),
                                        Text(_selectedStatus, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade700)),
                                      ]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('PO Number', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                            decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                            child: Text(widget.order.poNumber, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Supplier', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: _selectedSupplier,
                                                isExpanded: true,
                                                onChanged: (val) => setState(() => _selectedSupplier = val!),
                                                items: widget.suppliers.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Status', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: _selectedStatus,
                                                isExpanded: true,
                                                onChanged: (val) => setState(() => _selectedStatus = val!),
                                                items: _editableStatuses.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Line Items Card
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Line Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
                                        SizedBox(height: 3),
                                        Text('Add or remove medicines from this order.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                    TextButton.icon(
                                      onPressed: _addItem,
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Add item'),
                                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF0F4C81), textStyle: const TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                                if (_items.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('${_items.length} item${_items.length > 1 ? 's' : ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                  const SizedBox(height: 12),
                                ],
                                if (_items.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                                    child: Center(child: Text('No items. Click "+ Add item" to begin.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _items.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                                    itemBuilder: (ctx, index) {
                                      final item = _items[index];
                                      return Container(
                                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10), color: Colors.grey.shade50),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text('Item ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F4C81))),
                                                  InkWell(onTap: () => _removeItem(index), borderRadius: BorderRadius.circular(6), child: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400)),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(14),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 3,
                                                        child: _FieldLabel(
                                                          label: 'Product',
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                                            child: DropdownButtonHideUnderline(
                                                              child: DropdownButton<String>(
                                                                value: item.medicineName,
                                                                isExpanded: true,
                                                                onChanged: (val) => setState(() => item.medicineName = val!),
                                                                items: widget.medicines.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        flex: 1,
                                                        child: _FieldLabel(
                                                          label: 'Qty',
                                                          child: TextFormField(
                                                            initialValue: item.quantity.toString(),
                                                            keyboardType: TextInputType.number,
                                                            style: const TextStyle(fontSize: 14),
                                                            decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                                                            onChanged: (val) => setState(() => item.quantity = int.tryParse(val) ?? 0),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: _FieldLabel(
                                                          label: 'Purchase Price',
                                                          child: TextFormField(
                                                            initialValue: item.purchasePrice.toString(),
                                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                            style: const TextStyle(fontSize: 14),
                                                            decoration: InputDecoration(prefixText: 'Rs. ', contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                                                            onChanged: (val) => setState(() => item.purchasePrice = double.tryParse(val) ?? 0.0),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: _FieldLabel(
                                                          label: 'Selling Price',
                                                          child: TextFormField(
                                                            initialValue: item.sellingPrice.toString(),
                                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                            style: const TextStyle(fontSize: 14),
                                                            decoration: InputDecoration(prefixText: 'Rs. ', contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                                                            onChanged: (val) => setState(() => item.sellingPrice = double.tryParse(val) ?? 0.0),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: _FieldLabel(
                                                          label: 'Discount (Rs.)',
                                                          child: TextFormField(
                                                            initialValue: item.discount.toString(),
                                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                            style: const TextStyle(fontSize: 14),
                                                            decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                                                            onChanged: (val) => setState(() => item.discount = double.tryParse(val) ?? 0.0),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 2,
                                                        child: _FieldLabel(
                                                          label: 'Expiry Date',
                                                          child: InkWell(
                                                            onTap: () async {
                                                              final date = await showDatePicker(
                                                                context: context,
                                                                initialDate: item.expiryDate ?? DateTime.now().add(const Duration(days: 365)),
                                                                firstDate: DateTime.now(),
                                                                lastDate: DateTime.now().add(const Duration(days: 3650)),
                                                              );
                                                              if (date != null) setState(() => item.expiryDate = date);
                                                            },
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                                                              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                                              child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  Text(
                                                                    item.expiryDate != null ? _dateFormat.format(item.expiryDate!) : 'Select date',
                                                                    style: TextStyle(fontSize: 14, color: item.expiryDate != null ? const Color(0xFF1A2E2B) : Colors.grey.shade500),
                                                                  ),
                                                                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade500),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        flex: 1,
                                                        child: _FieldLabel(
                                                          label: 'Subtotal',
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                                                            decoration: BoxDecoration(color: Colors.blue.shade50, border: Border.all(color: Colors.blue.shade100), borderRadius: BorderRadius.circular(8)),
                                                            child: Text('Rs. ${item.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F4C81))),
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
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // ─── RIGHT COLUMN ─────────────────────────────────────
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Amounts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
                            const SizedBox(height: 3),
                            const Text('Live totals based on line items.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 18),
                            Text('Notes (Optional)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                              child: TextField(
                                controller: _notesController,
                                maxLines: 3,
                                style: const TextStyle(fontSize: 14),
                                decoration: const InputDecoration(hintText: 'Optional notes...', border: InputBorder.none, contentPadding: EdgeInsets.all(12)),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Tax Rate
                            Text('Tax Rate (%)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _taxController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                suffixText: '%',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),

                            const SizedBox(height: 12),

                            // Paid Amount
                            Text('Paid Amount', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _paidController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                prefixText: 'Rs. ',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),

                            const SizedBox(height: 20),
                            Divider(color: Colors.grey.shade200),
                            const SizedBox(height: 12),
                            _SummaryRow(label: 'Subtotal', value: 'Rs. ${_subtotal.toStringAsFixed(0)}'),
                            const SizedBox(height: 6),
                            _SummaryRow(label: 'Total Discount', value: '- Rs. ${_totalDiscount.toStringAsFixed(0)}', valueColor: Colors.orange.shade700),
                            const SizedBox(height: 6),
                            _SummaryRow(label: 'Tax (${_taxRate.toStringAsFixed(1)}%)', value: '+ Rs. ${_taxAmount.toStringAsFixed(0)}', valueColor: Colors.blue.shade700),
                            const SizedBox(height: 12),
                            Divider(color: Colors.grey.shade200),
                            const SizedBox(height: 6),
                            _SummaryRow(label: 'Total', value: 'Rs. ${_total.toStringAsFixed(0)}', valueColor: const Color(0xFF1A2E2B)),
                            const SizedBox(height: 6),
                            _SummaryRow(label: 'Paid Amount', value: '- Rs. ${_paidAmount.toStringAsFixed(0)}', valueColor: Colors.green.shade700),
                            const SizedBox(height: 12),
                            Divider(color: Colors.grey.shade200),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Balance Due', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _balanceDue > 0 ? Colors.orange.shade800 : Colors.green.shade800)),
                                Text('Rs. ${_balanceDue.abs().toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _balanceDue > 0 ? Colors.orange.shade800 : Colors.green.shade800)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), foregroundColor: Colors.grey.shade700),
                    child: const Text('Discard'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: canSave
                        ? () {
                            final updated = PurchaseOrder(
                              id: widget.order.id,
                              poNumber: widget.order.poNumber,
                              supplierName: _selectedSupplier,
                              orderDate: widget.order.orderDate,
                              items: List.from(_items),
                              status: _selectedStatus,
                              notes: _notesController.text,
                              taxRate: _taxRate,
                              paidAmount: _paidAmount,
                            );
                            widget.onSave(updated);
                          }
                        : null,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C81),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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


class _FieldLabel extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldLabel({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? const Color(0xFF1A2E2B))),
      ],
    );
  }
}

class _OrderDetailDialog extends StatelessWidget {
  final PurchaseOrder order;
  final VoidCallback onMarkReceived;

  const _OrderDetailDialog({required this.order, required this.onMarkReceived});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final canReceive = order.status == 'Ordered' || order.status == 'Partially Received';
    final isPaid = order.balanceDue <= 0;

    return Dialog(
      backgroundColor: const Color(0xFFF5F6FA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 660,
        constraints: const BoxConstraints(maxHeight: 860),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Dialog Header ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4C81).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF0F4C81), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Purchase Invoice', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
                        Text(order.poNumber, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context), splashRadius: 20),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),

            // ── Body ─────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // ── Purchase Total Banner ─────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0F4C81).withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F4C81).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.local_shipping_outlined, color: Color(0xFF0F4C81), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Purchase total', style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 3),
                                Text(
                                  'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F4C81)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${order.items.length} received item${order.items.length != 1 ? 's' : ''} · ${order.supplierName}',
                                  style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                                ),
                              ],
                            ),
                          ),
                          _StatusBadge(status: order.status),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Purchase Overview Card ────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Purchase Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
                          Text('Supplier, date, and settlement details for this purchase.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          const SizedBox(height: 16),
                          // Row 1: PO Number + Date
                          Row(
                            children: [
                              Expanded(
                                child: _InvoiceDetailRow(
                                  icon: Icons.tag,
                                  label: 'Purchase no.',
                                  value: order.poNumber,
                                  valueBold: true,
                                ),
                              ),
                              Expanded(
                                child: _InvoiceDetailRow(
                                  icon: Icons.calendar_today_outlined,
                                  label: 'Date',
                                  value: dateFormat.format(order.orderDate),
                                  valueBold: true,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 20, color: Colors.grey.shade100),
                          // Row 2: Supplier
                          _InvoiceDetailRow(
                            icon: Icons.storefront_outlined,
                            label: 'Supplier',
                            value: order.supplierName,
                          ),
                          Divider(height: 20, color: Colors.grey.shade100),
                          // Row 3: Paid Amount + Payment Status
                          Row(
                            children: [
                              Expanded(
                                child: _InvoiceDetailRow(
                                  icon: Icons.payments_outlined,
                                  label: 'Paid amount',
                                  value: 'Rs. ${order.paidAmount.toStringAsFixed(0)}',
                                  valueColor: Colors.green.shade700,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Payment status', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
                                        border: Border.all(color: isPaid ? Colors.green.shade300 : Colors.orange.shade300),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isPaid ? 'PAID' : 'PARTIAL',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isPaid ? Colors.green.shade700 : Colors.orange.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Items Card ───────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
                          Text('Products and quantities recorded on this supplier invoice.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          const SizedBox(height: 14),
                          // Table header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text('PRODUCT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 0.5))),
                                Expanded(flex: 2, child: Text('QTY × PRICE', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 0.5))),
                                Expanded(flex: 1, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 0.5))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: order.items.length,
                            separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade100),
                            itemBuilder: (ctx, i) {
                              final item = order.items[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                child: Row(
                                  children: [
                                    Expanded(flex: 3, child: Text(item.medicineName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${item.quantity} × Rs. ${item.purchasePrice.toStringAsFixed(0)}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        'Rs. ${item.subtotal.toStringAsFixed(0)}',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Totals Section ───────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        children: [
                          _TotalRow(label: 'Subtotal', value: 'Rs. ${order.subtotal.toStringAsFixed(0)}'),
                          const SizedBox(height: 8),
                          _TotalRow(
                            label: 'Tax (${order.taxRate.toStringAsFixed(1)}%)',
                            value: 'Rs. ${order.taxAmount.toStringAsFixed(0)}',
                            valueColor: Colors.grey.shade600,
                          ),
                          Divider(height: 20, color: Colors.grey.shade200),
                          _TotalRow(
                            label: 'Total Amount',
                            value: 'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                            isBold: true,
                          ),
                          const SizedBox(height: 8),
                          _TotalRow(
                            label: 'Paid Amount',
                            value: '− Rs. ${order.paidAmount.toStringAsFixed(0)}',
                            valueColor: Colors.green.shade700,
                          ),
                          Divider(height: 20, color: Colors.grey.shade200),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: order.balanceDue > 0 ? Colors.orange.shade50 : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: order.balanceDue > 0 ? Colors.orange.shade200 : Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Balance Due', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: order.balanceDue > 0 ? Colors.orange.shade800 : Colors.green.shade800)),
                                Text(
                                  'Rs. ${order.balanceDue.abs().toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: order.balanceDue > 0 ? Colors.orange.shade800 : Colors.green.shade800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Notes
                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.notes_outlined, size: 16, color: Colors.grey.shade500),
                            const SizedBox(width: 8),
                            Expanded(child: Text(order.notes!, style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), foregroundColor: Colors.grey.shade700),
                    child: const Text('Close'),
                  ),
                  if (canReceive) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: onMarkReceived,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Mark as Received', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
}

// ── Invoice helper widgets ───────────────────────────────────────────────────
class _InvoiceDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool valueBold;
  final Color? valueColor;
  const _InvoiceDetailRow({required this.icon, required this.label, required this.value, this.valueBold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500, color: valueColor ?? const Color(0xFF1A2E2B))),
            ],
          ),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;
  const _TotalRow({required this.label, required this.value, this.isBold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: isBold ? FontWeight.w700 : FontWeight.w400)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.w700 : FontWeight.w600, color: valueColor ?? const Color(0xFF1A2E2B))),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// HELPER COMPONENTS
// ---------------------------------------------------------------------------
void _showCustomSnackBar(BuildContext context, String message, {bool isError = false}) {
  final screenWidth = MediaQuery.of(context).size.width;
  const snackBarWidth = 400.0;
  final leftMargin = screenWidth > snackBarWidth + 48
      ? screenWidth - snackBarWidth - 24
      : 24.0;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(bottom: 24, right: 24, left: leftMargin),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
    ),
  );
}
