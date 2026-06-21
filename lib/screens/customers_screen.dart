import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// DATA MODEL
// ---------------------------------------------------------------------------
class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final double totalPurchases;
  final double pendingAmount;
  final double advanceAmount;
  final DateTime lastVisit;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    required this.totalPurchases,
    this.pendingAmount = 0.0,
    this.advanceAmount = 0.0,
    required this.lastVisit,
  });

  Customer copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    double? totalPurchases,
    double? pendingAmount,
    double? advanceAmount,
    DateTime? lastVisit,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      lastVisit: lastVisit ?? this.lastVisit,
    );
  }
}

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
  static const Color primary = Color(0xFF0F4C81);
  static const Color accent = Color(0xFF1976D2);
  static const Color bg = Color(0xFFF4F7F6);
  static const Color textDark = Color(0xFF1A2E2B);

  // TODO: Replace with real-time stream from Firestore 'customers' collection
  final List<Customer> _customers = [
    Customer(id: '1', name: 'Ahmed Raza', phone: '0300-1234567', email: 'ahmed@example.com', address: 'Lahore', totalPurchases: 4500, pendingAmount: 500, lastVisit: DateTime.now().subtract(const Duration(days: 2))),
    Customer(id: '2', name: 'Sara Khan', phone: '0321-7654321', totalPurchases: 1200, advanceAmount: 200, lastVisit: DateTime.now().subtract(const Duration(days: 5))),
    Customer(id: '3', name: 'Hamid Butt', phone: '0333-9988776', email: 'hamid.b@example.com', totalPurchases: 8900, pendingAmount: 1500, lastVisit: DateTime.now().subtract(const Duration(days: 1))),
    Customer(id: '4', name: 'Nadia Malik', phone: '0301-1122334', totalPurchases: 340, lastVisit: DateTime.now().subtract(const Duration(days: 12))),
    Customer(id: '5', name: 'Usman Tariq', phone: '0345-5566778', email: 'usman.t@example.com', address: 'Karachi', totalPurchases: 12500, advanceAmount: 5000, lastVisit: DateTime.now().subtract(const Duration(days: 0))),
    Customer(id: '6', name: 'Ayesha Ali', phone: '0312-4455667', totalPurchases: 750, lastVisit: DateTime.now().subtract(const Duration(days: 8))),
    Customer(id: '7', name: 'Zainab Shah', phone: '0302-9988112', email: 'zainab@example.com', totalPurchases: 2100, pendingAmount: 300, lastVisit: DateTime.now().subtract(const Duration(days: 4))),
    Customer(id: '8', name: 'Bilal Qureshi', phone: '0331-2233445', address: 'Islamabad', totalPurchases: 5600, advanceAmount: 1000, lastVisit: DateTime.now().subtract(const Duration(days: 15))),
  ];

  String _searchQuery = '';
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  List<Customer> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    final query = _searchQuery.toLowerCase();
    return _customers.where((c) {
      return c.name.toLowerCase().contains(query) || c.phone.toLowerCase().contains(query);
    }).toList();
  }

  void _addCustomer(Customer c) {
    // TODO: On save, write to Firestore (add doc) instead of updating local list
    setState(() {
      _customers.insert(0, c);
    });
    // If not searching, animate it in
    if (_searchQuery.isEmpty && _listKey.currentState != null) {
      _listKey.currentState!.insertItem(0, duration: const Duration(milliseconds: 300));
    }
  }

  void _updateCustomer(Customer c) {
    // TODO: On save, write to Firestore (update doc) instead of updating local list
    setState(() {
      final index = _customers.indexWhere((x) => x.id == c.id);
      if (index != -1) {
        _customers[index] = c;
      }
    });
  }

  void _deleteCustomer(Customer c) {
    // TODO: On delete, remove document from Firestore 'customers' collection
    final index = _filteredCustomers.indexWhere((x) => x.id == c.id);
    final realIndex = _customers.indexWhere((x) => x.id == c.id);
    
    if (index != -1 && _listKey.currentState != null && _searchQuery.isEmpty) {
      _listKey.currentState!.removeItem(
        index,
        (context, animation) => _buildAnimatedRow(c, animation, index),
        duration: const Duration(milliseconds: 250),
      );
    }
    
    setState(() {
      if (realIndex != -1) _customers.removeAt(realIndex);
    });
    
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
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
                  const Text('Customer Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E2B))),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.grey.shade500,
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 24,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Name', c.name),
              _buildDetailRow('Phone Number', c.phone),
              _buildDetailRow('Email', c.email?.isNotEmpty == true ? c.email! : '--'),
              _buildDetailRow('Address', c.address?.isNotEmpty == true ? c.address! : '--'),
              _buildDetailRow('Total Purchases', 'Rs. ${NumberFormat('#,##0').format(c.totalPurchases)}'),
              _buildDetailRow('Pending Amount', 'Rs. ${NumberFormat('#,##0').format(c.pendingAmount)}'),
              _buildDetailRow('Advance Amount', 'Rs. ${NumberFormat('#,##0').format(c.advanceAmount)}'),
              _buildDetailRow('Last Visit', DateFormat('dd MMM yyyy').format(c.lastVisit)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
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
          // ── Header ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customers',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your customer records',
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ],
              ),
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
                    Text(
                      'Total Customers: ${_customers.length}',
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
                        Expanded(flex: 2, child: _headerText('Email')),
                        Expanded(flex: 2, child: _headerText('Total Purchases', textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: _headerText('Pending (Rs)')),
                        Expanded(flex: 2, child: _headerText('Advance (Rs)')),
                        Expanded(flex: 2, child: _headerText('Last Visit')),
                        const SizedBox(width: 140), // Actions space
                      ],
                    ),
                  ),

                  // Table Body
                  Expanded(
                    child: displayList.isEmpty
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
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isEven;

  const _CustomerRow({
    required this.customer,
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
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.customer.email?.isNotEmpty == true ? widget.customer.email! : '--',
                  style: TextStyle(color: widget.customer.email?.isNotEmpty == true ? Colors.grey.shade700 : Colors.grey.shade400),
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
                flex: 2,
                child: Text(
                  widget.customer.pendingAmount > 0 ? 'Rs. ${NumberFormat('#,##0').format(widget.customer.pendingAmount)}' : '--',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.customer.advanceAmount > 0 ? 'Rs. ${NumberFormat('#,##0').format(widget.customer.advanceAmount)}' : '--',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1976D2)),
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
                width: 140,
                child: AnimatedOpacity(
                  opacity: _isHovering ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ActionButton(
                        icon: Icons.visibility_outlined,
                        color: Colors.green.shade600,
                        onTap: widget.onView,
                        tooltip: 'View',
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
        width: 500,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Customer' : 'Add Customer',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E2B)),
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
              _buildField(
                controller: _nameController,
                label: 'Customer Name',
                hint: 'e.g. Ali Khan',
                icon: Icons.person_outline,
                validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'e.g. 0300-1234567',
                icon: Icons.phone_outlined,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Phone number is required';
                  if (val.length < 10) return 'Enter a valid phone number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _emailController,
                label: 'Email Address (Optional)',
                hint: 'e.g. ali@example.com',
                icon: Icons.email_outlined,
                validator: (val) {
                  if (val != null && val.isNotEmpty && !val.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _addressController,
                label: 'Address (Optional)',
                hint: 'Enter full address',
                icon: Icons.location_on_outlined,
                maxLines: 3,
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
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C81),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(isEditing ? 'Save Changes' : 'Save Customer', style: const TextStyle(fontWeight: FontWeight.w600)),
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
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.grey.shade400, size: 20) : Padding(
              padding: const EdgeInsets.only(bottom: 48.0),
              child: Icon(icon, color: Colors.grey.shade400, size: 20),
            ),
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
