import 'package:flutter/material.dart';
import '../widgets/executive_header.dart';
import 'package:intl/intl.dart';

import '../services/database_helper.dart';
import '../models/customer.dart';
// ---------------------------------------------------------------------------
// SCREEN
// ---------------------------------------------------------------------------
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  // Theme Colors
  static const primary = Color(0xFF0F4C81);
  static const Color textDark = Color(0xFF1A2E2B);

  List<Customer> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final customers = await DatabaseHelper.instance.getCustomers();
    if (mounted) {
      setState(() {
        _customers = customers;
        _isLoading = false;
      });
    }
  }

  String _searchQuery = '';
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  List<Customer> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    final query = _searchQuery.toLowerCase();
    return _customers.where((c) {
      return c.name.toLowerCase().contains(query) || c.phone.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _addCustomer(Customer c) async {
    await DatabaseHelper.instance.insertCustomer(c);
    await _loadCustomers();
  }

  Future<void> _updateCustomer(Customer c) async {
    await DatabaseHelper.instance.updateCustomer(c);
    await _loadCustomers();
  }

  Future<void> _deleteCustomer(Customer c) async {
    if (c.id != null) {
      await DatabaseHelper.instance.deleteCustomer(c.id!);
      await _loadCustomers();
    }
    
    // Calculate margin for bottom right positioning
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
            Expanded(
              child: Text(
                '${c.name} deleted successfully',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 24, right: 24, left: leftMargin),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
      ),
    );
  }

  void _showCustomerDialog({Customer? existingCustomer}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Customer Dialog',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: _CustomerDialog(
              existingCustomer: existingCustomer,
              onSave: (customer) {
                if (existingCustomer == null) {
                  _addCustomer(customer);
                } else {
                  _updateCustomer(customer);
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _showViewCustomerDialog(Customer c) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Customer Ledger Dialog',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: _CustomerLedgerDialog(customer: c),
          ),
        );
      },
    );
  }


  void _recordPayment(Customer c) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Record Payment Dialog',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: _RecordPaymentDialog(customer: c),
          ),
        );
      },
    );
  }

  void _confirmDelete(Customer c) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: const Text('Delete Customer', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete ${c.name}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCustomer(c);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade700,
                elevation: 0,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredCustomers;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Executive Header ──────────────────────────────────────────────
          const ExecutiveHeader(title: 'Customers', subtitle: 'Manage customer records, ledgers, and payment history from a unified workspace.'),
          const SizedBox(height: 32),

          // ── Add Button Row ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showCustomerDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  shadowColor: primary.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Filter Row ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people, size: 16, color: primary),
                    const SizedBox(width: 8),
                    _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          'Total Customers: ${displayList.length}',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: primary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
          const SizedBox(height: 24),

          // ── Data Table Card ─────────────────────────────────────
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: _headerText('Customer Name')),
                        Expanded(flex: 2, child: _headerText('Phone Number')),
                        Expanded(flex: 2, child: _headerText('Total Purchases', textAlign: TextAlign.center)),
                        Expanded(flex: 4, child: _headerText('Balance', textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: _headerText('Last Visit')),
                        const SizedBox(width: 140), // Actions space
                      ],
                    ),
                  ),

                  // Table Body
                  Expanded(
                    child: _isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : displayList.isEmpty
                            ? _buildEmptyState()
                            : _searchQuery.isEmpty 
                                ? AnimatedList(
                                    key: _listKey,
                                    initialItemCount: displayList.length,
                                    itemBuilder: (context, index, animation) {
                                      return _buildAnimatedRow(displayList[index], animation, index);
                                    },
                                  )
                                : ListView.builder(
                                    itemCount: displayList.length,
                                    itemBuilder: (context, index) {
                                      return _CustomerRow(
                                        customer: displayList[index],
                                        onPayment: () => _recordPayment(displayList[index]),
                                        onView: () => _showViewCustomerDialog(displayList[index]),
                                        onEdit: () => _showCustomerDialog(existingCustomer: displayList[index]),
                                        onDelete: () => _confirmDelete(displayList[index]),
                                        isEven: index % 2 == 0,
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerText(String text, {TextAlign textAlign = TextAlign.left}) {
    return Text(
      text.toUpperCase(),
      textAlign: textAlign,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          const Text(
            'No customers found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Try adjusting your search filters'
                : 'Add a new customer to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedRow(Customer customer, Animation<double> animation, int index) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: _CustomerRow(
          customer: customer,
          onPayment: () => _recordPayment(customer),
          onView: () => _showViewCustomerDialog(customer),
          onEdit: () => _showCustomerDialog(existingCustomer: customer),
          onDelete: () => _confirmDelete(customer),
          isEven: index % 2 == 0,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CUSTOMER ROW WIDGET
// ---------------------------------------------------------------------------
class _CustomerRow extends StatefulWidget {
  final Customer customer;
  final VoidCallback onPayment;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isEven;

  const _CustomerRow({
    required this.customer,
    required this.onPayment,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.isEven,
  });

  @override
  State<_CustomerRow> createState() => _CustomerRowState();
}

class _CustomerRowState extends State<_CustomerRow> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        decoration: BoxDecoration(
          color: _isHovering 
              ? Colors.blueGrey.shade50.withValues(alpha: 0.3) 
              : (widget.isEven ? Colors.transparent : Colors.grey.shade50.withValues(alpha: 0.5)),
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  widget.customer.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B)),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.customer.phone,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Rs. ${NumberFormat('#,##0').format(widget.customer.totalPurchases)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F4C81)),
                ),
              ),
              Expanded(
                flex: 4,
                child: Builder(
                  builder: (context) {
                    final double balance = widget.customer.advanceAmount - widget.customer.pendingAmount;
                    final bool isPositive = balance >= 0;
                    return Text(
                      balance == 0 
                          ? '--' 
                          : '${isPositive ? '+' : '-'}Rs. ${NumberFormat('#,##0').format(balance.abs())}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600, 
                        color: balance == 0 ? Colors.grey : (isPositive ? const Color(0xFF1976D2) : Colors.red),
                      ),
                    );
                  }
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  DateFormat('dd MMM yyyy').format(widget.customer.lastVisit),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              SizedBox(
                width: 160,
                child: AnimatedOpacity(
                  opacity: _isHovering ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ActionButton(
                        icon: Icons.credit_card_outlined,
                        color: Colors.green.shade600,
                        onTap: widget.onPayment,
                        tooltip: 'Record Payment',
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.visibility_outlined,
                        color: const Color(0xFF7E57C2),
                        onTap: widget.onView,
                        tooltip: 'View Ledger',
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.edit_outlined,
                        color: const Color(0xFF1976D2),
                        onTap: widget.onEdit,
                        tooltip: 'Edit',
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.delete_outline,
                        color: Colors.red.shade400,
                        onTap: widget.onDelete,
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({required this.icon, required this.color, required this.onTap, required this.tooltip});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isHovering ? widget.color.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon, size: 18, color: _isHovering ? widget.color : Colors.grey.shade500),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ADD/EDIT CUSTOMER DIALOG
// ---------------------------------------------------------------------------
class _CustomerDialog extends StatefulWidget {
  final Customer? existingCustomer;
  final ValueChanged<Customer> onSave;

  const _CustomerDialog({this.existingCustomer, required this.onSave});

  @override
  State<_CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<_CustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingCustomer?.name ?? '');
    _phoneController = TextEditingController(text: widget.existingCustomer?.phone ?? '');
    _emailController = TextEditingController(text: widget.existingCustomer?.email ?? '');
    _addressController = TextEditingController(text: widget.existingCustomer?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final customer = Customer(
        id: widget.existingCustomer?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        totalPurchases: widget.existingCustomer?.totalPurchases ?? 0.0,
        pendingAmount: widget.existingCustomer?.pendingAmount ?? 0.0,
        advanceAmount: widget.existingCustomer?.advanceAmount ?? 0.0,
        lastVisit: widget.existingCustomer?.lastVisit ?? DateTime.now(),
      );
      
      Navigator.of(context).pop();
      widget.onSave(customer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCustomer != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF0FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_add_alt_1, color: Color(0xFF5D5FEF), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Customer' : 'Add New Customer',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E2B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEditing ? 'Update existing customer details' : 'Create a new customer profile',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.grey.shade500,
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 24,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Profile Section Box
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E2B))),
                    const SizedBox(height: 4),
                    Text('Capture the customer name and contact details used across invoices and ledgers.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    const SizedBox(height: 24),
                    
                    _buildField(
                      controller: _nameController,
                      label: 'Customer name',
                      hint: 'e.g. Al-Nafi Traders',
                      validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _phoneController,
                      label: 'Phone number',
                      hint: 'e.g. 03001234567',
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Phone number is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'e.g. Suite 4, Bilal Plaza, Lahore',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Actions
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D5FEF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isEditing ? 'Save Changes' : 'Add Customer', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4A5568))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5D5FEF), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// VIEW CUSTOMER LEDGER DIALOG
// ---------------------------------------------------------------------------
class _LedgerEntry {
  final DateTime date;
  final String reference;
  final String description;
  final double debit;
  final double credit;
  final double balance;
  final double closingBalance;

  _LedgerEntry(this.date, this.reference, this.description, this.debit, this.credit, this.balance, this.closingBalance);
}

class _CustomerLedgerDialog extends StatefulWidget {
  final Customer customer;

  const _CustomerLedgerDialog({required this.customer});

  @override
  State<_CustomerLedgerDialog> createState() => _CustomerLedgerDialogState();
}

class _CustomerLedgerDialogState extends State<_CustomerLedgerDialog> {
  late final Future<List<_LedgerEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _loadEntries();
  }

  Future<List<_LedgerEntry>> _loadEntries() async {
    final customerId = widget.customer.id;
    if (customerId == null || customerId.isEmpty) {
      return [];
    }

    final rows = await DatabaseHelper.instance.getCustomerStatement(customerId, null, null);
    return rows.map((row) {
      return _LedgerEntry(
        DateTime.parse(row['date'].toString()),
        row['reference']?.toString() ?? '',
        row['description']?.toString() ?? '',
        (row['debit'] as num?)?.toDouble() ?? 0.0,
        (row['credit'] as num?)?.toDouble() ?? 0.0,
        (row['balance'] as num?)?.toDouble() ?? 0.0,
        (row['closing_balance'] as num?)?.toDouble() ?? (row['balance'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  double _closingBalance(List<_LedgerEntry> entries) {
    if (entries.isNotEmpty) return entries.first.closingBalance;
    if (widget.customer.pendingAmount > 0) return widget.customer.pendingAmount;
    return widget.customer.advanceAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Container(
        width: 850,
        padding: const EdgeInsets.all(32),
        child: FutureBuilder<List<_LedgerEntry>>(
          future: _entriesFuture,
          builder: (context, snapshot) {
            final entries = snapshot.data ?? const <_LedgerEntry>[];
            final closingBalance = _closingBalance(entries);
            final hasAdvance = closingBalance < 0;
            final balanceLabel = hasAdvance ? 'Advance credit' : (closingBalance > 0 ? 'Pending balance' : 'Cleared');
            final balanceColor = hasAdvance ? Colors.green.shade700 : (closingBalance > 0 ? Colors.red.shade700 : Colors.grey.shade600);
            final totalDebit = entries.fold<double>(0.0, (sum, e) => sum + e.debit);
            final totalCredit = entries.fold<double>(0.0, (sum, e) => sum + e.credit);

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 560,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: 560,
                child: Center(
                  child: Text(
                    'Failed to load customer ledger',
                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.receipt_long, color: Color(0xFF7E57C2), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customer Ledger',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E2B)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Financial statement for ${widget.customer.name}',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: Colors.grey.shade500,
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 24,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.account_balance_wallet, color: Color(0xFF4CAF50)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.customer.name,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E2B)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Live customer statement and running receivable balance.',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(widget.customer.phone, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: hasAdvance ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    balanceLabel,
                                    style: TextStyle(fontSize: 12, color: balanceColor),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rs. ${NumberFormat('#,##0').format(closingBalance)}',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: balanceColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryBox(
                                title: 'Total debit',
                                value: 'Rs. ${NumberFormat('#,##0').format(totalDebit)}',
                                subtitle: 'Amount billed to the customer',
                                bgColor: Colors.red.shade50,
                                valueColor: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSummaryBox(
                                title: 'Total credit',
                                value: 'Rs. ${NumberFormat('#,##0').format(totalCredit)}',
                                subtitle: 'Payments and returns applied',
                                bgColor: Colors.green.shade50,
                                valueColor: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSummaryBox(
                                title: 'Closing balance',
                                value: 'Rs. ${NumberFormat('#,##0').format(closingBalance)}',
                                subtitle: balanceLabel,
                                bgColor: Colors.blue.shade50,
                                valueColor: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: _headerText('DATE')),
                        Expanded(flex: 2, child: _headerText('REFERENCE')),
                        Expanded(flex: 4, child: _headerText('DESCRIPTION')),
                        Expanded(flex: 2, child: _headerText('DEBIT (OWED)')),
                        Expanded(flex: 2, child: _headerText('CREDIT (PAID)')),
                        Expanded(flex: 2, child: _headerText('BALANCE')),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 250,
                    child: entries.isEmpty
                        ? Center(
                            child: Text(
                              'No ledger activity found.',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: entries.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1, color: Color(0xFFF5F5F5)),
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        DateFormat('dd MMM yyyy').format(entry.date),
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(entry.reference, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Text(entry.description, style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        entry.debit > 0 ? 'Rs. ${NumberFormat('#,##0').format(entry.debit)}' : '-',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red.shade600),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        entry.credit > 0 ? 'Rs. ${NumberFormat('#,##0').format(entry.credit)}' : '-',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green.shade600),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Rs. ${NumberFormat('#,##0').format(entry.balance)}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryBox({
    required String title,
    required String value,
    required String subtitle,
    required Color bgColor,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ]
        ],
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5),
    );
  }
}

// ---------------------------------------------------------------------------
// RECORD CUSTOMER PAYMENT DIALOG
// ---------------------------------------------------------------------------
class _RecordPaymentDialog extends StatefulWidget {
  final Customer customer;

  const _RecordPaymentDialog({required this.customer});

  @override
  State<_RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<_RecordPaymentDialog> {
  final _amountController = TextEditingController(text: '0');
  final _receiptController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'Cash';
  bool _isGeneralReceipt = true;

  @override
  void initState() {
    super.initState();
    _receiptController.text = 'PAY-CUST-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _receiptController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isAdvance = widget.customer.advanceAmount > 0;
    bool hasPending = widget.customer.pendingAmount > 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5), // Light purple
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.payment, color: Color(0xFF7E57C2), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Receive Customer Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E2B))),
                        const SizedBox(height: 4),
                        Text('Record payment from ${widget.customer.name}', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.grey.shade500,
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 24,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Status Box (Advance/Pending)
              if (isAdvance || hasPending)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isAdvance ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isAdvance ? Colors.green.shade200 : Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(isAdvance ? Icons.check_circle_outline : Icons.info_outline, color: isAdvance ? Colors.green.shade600 : Colors.red.shade600, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isAdvance ? 'Advance credit' : 'Pending balance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                            const SizedBox(height: 4),
                            Text('Rs. ${NumberFormat('#,##0').format(isAdvance ? widget.customer.advanceAmount : widget.customer.pendingAmount)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isAdvance ? Colors.green.shade700 : Colors.red.shade700)),
                            const SizedBox(height: 4),
                            Text(isAdvance ? 'This customer already has advance credit available in the ledger.' : 'This customer has an outstanding balance.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Invoice Selection Section
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Invoice Selection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E2B))),
                    const SizedBox(height: 4),
                    Text('Apply the receipt to a single invoice or keep it unassigned.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isGeneralReceipt = true;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: _isGeneralReceipt ? const Color(0xFF5D5FEF) : Colors.grey.shade200, width: _isGeneralReceipt ? 2 : 1),
                          borderRadius: BorderRadius.circular(12),
                          color: _isGeneralReceipt ? const Color(0xFFF3F3FF) : Colors.white,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _isGeneralReceipt ? const Color(0xFFE0E0FF) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.account_balance_wallet_outlined, color: _isGeneralReceipt ? const Color(0xFF5D5FEF) : Colors.grey.shade600),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('General receipt', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _isGeneralReceipt ? const Color(0xFF5D5FEF) : Colors.grey.shade800)),
                                  const SizedBox(height: 4),
                                  Text('Receive payment without linking it to a specific invoice.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            if (_isGeneralReceipt)
                              const Icon(Icons.check_circle, color: Color(0xFF5D5FEF)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Details Section
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E2B))),
                    const SizedBox(height: 4),
                    Text('Capture the receipt amount, method, and reference number.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildField(
                            label: 'Amount received',
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Payment method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                              const SizedBox(height: 8),
                              Container(
                                height: 52, // Match TextField height approximately
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _paymentMethod,
                                    icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                    items: ['Cash', 'Bank Transfer', 'Credit Card'].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value, style: const TextStyle(fontSize: 14)),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      setState(() {
                                        _paymentMethod = newValue!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Receipt / reference no.',
                      controller: _receiptController,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Notes',
                      controller: _notesController,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      
                      final screenWidth = MediaQuery.of(context).size.width;
                      const snackBarWidth = 400.0;
                      final leftMargin = screenWidth > snackBarWidth + 48 ? screenWidth - snackBarWidth - 24 : 24.0;
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Payment recorded successfully',
                                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green.shade600,
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.only(bottom: 24, right: 24, left: leftMargin),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D5FEF),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Record payment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5D5FEF), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
