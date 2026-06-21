import 'package:flutter/material.dart';

// TODO: Replace with Firestore models
class CartItem {
  final String medicineId;
  final String name;
  final double unitPrice;
  int quantity;

  CartItem({
    required this.medicineId,
    required this.name,
    required this.unitPrice,
    this.quantity = 1,
  });

  double get subtotal => unitPrice * quantity;
}

class SaleRecord {
  final String invoiceId;
  final String customerName;
  final DateTime date;
  final double totalAmount;

  SaleRecord({
    required this.invoiceId,
    required this.customerName,
    required this.date,
    required this.totalAmount,
  });
}

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  // Dummy Data
  final List<CartItem> _cartItems = [
    CartItem(medicineId: '1', name: 'Panadol 500mg', unitPrice: 20.0, quantity: 2),
    CartItem(medicineId: '2', name: 'Augmentin 625mg', unitPrice: 150.0, quantity: 1),
    CartItem(medicineId: '3', name: 'Brufen 400mg', unitPrice: 35.0, quantity: 3),
  ];

  final List<SaleRecord> _recentSales = [
    SaleRecord(invoiceId: 'INV-1042', customerName: 'Ahmed Raza', date: DateTime.now().subtract(const Duration(minutes: 5)), totalAmount: 450.0),
    SaleRecord(invoiceId: 'INV-1041', customerName: 'Sara Khan', date: DateTime.now().subtract(const Duration(minutes: 45)), totalAmount: 1250.0),
    SaleRecord(invoiceId: 'INV-1040', customerName: 'Hamid Butt', date: DateTime.now().subtract(const Duration(hours: 2)), totalAmount: 320.0),
    SaleRecord(invoiceId: 'INV-1039', customerName: 'Nadia Malik', date: DateTime.now().subtract(const Duration(hours: 5)), totalAmount: 890.0),
    SaleRecord(invoiceId: 'INV-1038', customerName: 'Usman Tariq', date: DateTime.now().subtract(const Duration(days: 1)), totalAmount: 150.0),
    SaleRecord(invoiceId: 'INV-1037', customerName: 'Walk-in Customer', date: DateTime.now().subtract(const Duration(days: 1, hours: 2)), totalAmount: 60.0),
  ];

  // Colors based on theme tokens
  static const Color primary = Color(0xFF0F4C81);
  static const Color accent = Color(0xFF1976D2);
  static const Color background = Color(0xFFF4F7F6);
  static const Color cardBg = Colors.white;

  void _updateQuantity(int index, int delta) {
    setState(() {
      final newQty = _cartItems[index].quantity + delta;
      if (newQty > 0) {
        _cartItems[index].quantity = newQty;
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
    });
  }

  double get _subtotal => _cartItems.fold(0, (sum, item) => sum + item.subtotal);
  double get _discount => 0.0; // Dummy default
  double get _tax => 0.0; // Dummy default
  double get _total => _subtotal - _discount + _tax;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure a minimum height so the cart card and summary never squish or overflow.
        // If the window is taller, it naturally fills the space.
        final minHeight = constraints.maxHeight > 850 ? constraints.maxHeight : 850.0;
        
        return SingleChildScrollView(
          child: SizedBox(
            height: minHeight,
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Column: 55%
                  Expanded(
                    flex: 55,
                    child: _buildNewSaleColumn(),
                  ),
                  const SizedBox(width: 24),
                  // Right Column: 45%
                  Expanded(
                    flex: 45,
                    child: _buildRecentSalesColumn(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewSaleColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Text(
          'New Sale / Billing',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A2E2B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create a new invoice',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),

        // Customer Search
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: _SaaSInputField(
                label: 'Customer',
                hintText: 'Search customer by name or phone...',
                icon: Icons.search,
              ),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: () {
                _showNewCustomerDialog(context);
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Customer'),
              style: TextButton.styleFrom(
                foregroundColor: primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Medicine Search
        const _SaaSInputField(
          label: 'Add Medicine',
          hintText: 'Search medicine by name or batch...',
          icon: Icons.medication_outlined,
        ),
        const SizedBox(height: 24),

        // Cart List
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Cart Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      _cartHeader('Item', flex: 3),
                      _cartHeader('Price', flex: 2),
                      _cartHeader('Qty', flex: 2),
                      _cartHeader('Subtotal', flex: 2, alignRight: true),
                      const SizedBox(width: 40), // Space for remove button
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade100),

                // Cart Items
                Expanded(
                  child: _cartItems.isEmpty
                      ? _buildEmptyCartState()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _cartItems.length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade50),
                          itemBuilder: (context, index) {
                            return _CartRow(
                              item: _cartItems[index],
                              onIncrease: () => _updateQuantity(index, 1),
                              onDecrease: () => _updateQuantity(index, -1),
                              onRemove: () => _removeItem(index),
                            );
                          },
                        ),
                ),
                
                Divider(height: 1, color: Colors.grey.shade100),
                // Bill Summary
                _buildBillSummary(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCartState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No items yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Search a medicine above to add',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillSummary() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _summaryRow('Subtotal', _subtotal, isBold: false),
          const SizedBox(height: 8),
          _summaryRow('Discount', _discount, isBold: false),
          const SizedBox(height: 8),
          _summaryRow('Tax', _tax, isBold: false),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          _summaryRow('Total', _total, isBold: true, isLarge: true),
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _cartItems.isEmpty ? null : _clearCart,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Clear Cart',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _cartItems.isEmpty ? null : () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Complete Sale / Print Invoice',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cartHeader(String title, {required int flex, bool alignRight = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        title.toUpperCase(),
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade400,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isBold = false, bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 18 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? primary : Colors.grey.shade600,
          ),
        ),
        Text(
          'Rs. ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isLarge ? 22 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? primary : const Color(0xFF1A2E2B),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSalesColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A2E2B),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: _recentSales.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final sale = _recentSales[index];
              return _TransactionTile(
                sale: sale,
                onView: () => _showInvoiceDialog(sale),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showInvoiceDialog(SaleRecord sale) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: cardBg,
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sale.invoiceId,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: primary),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _invoiceDetailRow('Customer', sale.customerName),
                const SizedBox(height: 12),
                _invoiceDetailRow('Date', '${sale.date.day}/${sale.date.month}/${sale.date.year} ${sale.date.hour}:${sale.date.minute.toString().padLeft(2, '0')}'),
                const SizedBox(height: 24),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 24),
                // Dummy items list
                const Text('Items:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Placeholder items for invoice ${sale.invoiceId}...', style: TextStyle(color: Colors.grey.shade500)),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text('Rs. ${sale.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: primary)),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {}, // TODO: Implement Print functionality
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Print Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNewCustomerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'New Customer',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2E2B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: Colors.grey.shade500,
                      onPressed: () => Navigator.of(context).pop(),
                      splashRadius: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SaaSInputField(
                  label: 'Customer Name',
                  hintText: 'Enter full name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                const _SaaSInputField(
                  label: 'Phone Number',
                  hintText: 'Enter phone number',
                  icon: Icons.phone_outlined,
                ),
                const SizedBox(height: 16),
                const _SaaSInputField(
                  label: 'Email Address (Optional)',
                  hintText: 'Enter email address',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                const _SaaSInputField(
                  label: 'Address (Optional)',
                  hintText: 'Enter address',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        foregroundColor: Colors.grey.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        
                        // Calculate margin to position the 380px wide snackbar at the bottom right
                        final screenWidth = MediaQuery.of(context).size.width;
                        const snackBarWidth = 380.0;
                        final leftMargin = screenWidth > snackBarWidth + 48 
                            ? screenWidth - snackBarWidth - 24 
                            : 24.0;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Customer added successfully',
                                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF0F4C81),
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.only(bottom: 24, right: 24, left: leftMargin),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 8,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4C81),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Save Customer', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _invoiceDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CUSTOM WIDGETS
// ---------------------------------------------------------------------------

class _SaaSInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData icon;

  const _SaaSInputField({
    required this.label,
    required this.hintText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A2E2B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0F4C81), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _CartRow extends StatefulWidget {
  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const _CartRow({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  State<_CartRow> createState() => _CartRowState();
}

class _CartRowState extends State<_CartRow> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        color: _isHovering ? Colors.blueGrey.shade50.withValues(alpha: 0.3) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                widget.item.name,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Rs. ${widget.item.unitPrice.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  _StepperButton(icon: Icons.remove, onPressed: widget.onDecrease),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${widget.item.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  _StepperButton(icon: Icons.add, onPressed: widget.onIncrease),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Rs. ${widget.item.subtotal.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F4C81)),
              ),
            ),
            SizedBox(
              width: 40,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: _isHovering ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: Colors.red.shade300,
                    onPressed: widget.onRemove,
                    splashRadius: 20,
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

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _StepperButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, size: 14, color: Colors.grey.shade700),
      ),
    );
  }
}

class _TransactionTile extends StatefulWidget {
  final SaleRecord sale;
  final VoidCallback onView;

  const _TransactionTile({required this.sale, required this.onView});

  @override
  State<_TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<_TransactionTile> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: widget.onView,
            borderRadius: BorderRadius.circular(12),
            hoverColor: Colors.blueGrey.shade50.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4C81).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF0F4C81), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.sale.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A2E2B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.sale.invoiceId} • ${_formatTimeAgo(widget.sale.date)}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rs. ${widget.sale.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0F4C81)),
                      ),
                      const SizedBox(height: 6),
                      AnimatedOpacity(
                        opacity: _isHovering ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: Row(
                          children: [
                            Text(
                              'View',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey.shade600),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }
}
