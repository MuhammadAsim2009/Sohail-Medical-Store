import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/executive_header.dart';

// TODO: Replace local list with real-time Firestore stream from 'suppliers' collection

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

class Supplier {
  final String id;
  final String companyName;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final List<String> categoriesSupplied;
  final DateTime lastOrderDate;
  final double pendingAmount;
  final double advanceAmount;

  Supplier({
    required this.id,
    required this.companyName,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
    required this.categoriesSupplied,
    required this.lastOrderDate,
    this.pendingAmount = 0.0,
    this.advanceAmount = 0.0,
  });

  Supplier copyWith({
    String? id,
    String? companyName,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    List<String>? categoriesSupplied,
    DateTime? lastOrderDate,
  }) {
    return Supplier(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      categoriesSupplied: categoriesSupplied ?? this.categoriesSupplied,
      lastOrderDate: lastOrderDate ?? this.lastOrderDate,
    );
  }
}

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  // Theme Tokens
  static const Color _primaryColor = Color(0xFF0F4C81);
    static const Color _backgroundColor = Color(0xFFF4F7F6);

  String _searchQuery = '';

  // Dummy Data
  final List<Supplier> _suppliers = [
    Supplier(
      id: '1',
      companyName: 'PharmaCorp Inc.',
      contactPerson: 'Ali Khan',
      phone: '0300-1234567',
      email: 'ali@pharmacorp.com',
      address: '123 Business Road, Karachi',
      categoriesSupplied: ['Tablets', 'Syrups'],
      lastOrderDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Supplier(
      id: '2',
      companyName: 'MedLife Distributors',
      contactPerson: 'Sarah Ahmed',
      phone: '0321-7654321',
      email: 'sarah@medlife.com',
      address: '45 Health Ave, Lahore',
      categoriesSupplied: ['Injections', 'Capsules'],
      lastOrderDate: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Supplier(
      id: '3',
      companyName: 'Global Biotech',
      contactPerson: 'Usman Tariq',
      phone: '0333-9876543',
      email: 'usman@globalbio.com',
      address: '78 Bio Park, Islamabad',
      categoriesSupplied: ['Ointments', 'Drops'],
      lastOrderDate: DateTime.now().subtract(const Duration(days: 12)),
    ),
    Supplier(
      id: '4',
      companyName: 'CureAll Pharmaceuticals',
      contactPerson: 'Ayesha Raza',
      phone: '0345-1122334',
      email: 'ayesha@cureall.pk',
      address: 'Plot 12, Industrial Estate, Faisalabad',
      categoriesSupplied: ['Tablets', 'Injections', 'Syrups'],
      lastOrderDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Supplier(
      id: '5',
      companyName: 'HealWell Supplies',
      contactPerson: 'Bilal Hassan',
      phone: '0311-5566778',
      email: 'bhassan@healwell.com',
      address: 'Shop 4, Medicine Market, Multan',
      categoriesSupplied: ['First Aid', 'Bandages'],
      lastOrderDate: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Supplier(
      id: '6',
      companyName: 'Prime Meds Pvt Ltd',
      contactPerson: 'Zainab Qureshi',
      phone: '0301-9988776',
      email: 'zainab@primemeds.com',
      address: 'Suite 302, Prime Tower, Rawalpindi',
      categoriesSupplied: ['Vitamins', 'Supplements'],
      lastOrderDate: DateTime.now().subtract(const Duration(days: 8)),
    ),
    Supplier(
      id: '7',
      companyName: 'Apex Healthcare',
      contactPerson: 'Fahad Mustafa',
      phone: '0322-4455667',
      email: 'fahad@apexhealth.com',
      address: 'Apex Building, Shahrah-e-Faisal, Karachi',
      categoriesSupplied: ['Capsules', 'Ointments'],
      lastOrderDate: DateTime.now().subtract(const Duration(days: 15)),
    ),
    Supplier(
      id: '8',
      companyName: 'Nova Life Sciences',
      contactPerson: 'Sana Malik',
      phone: '0334-2233445',
      email: 'sana.malik@novalife.pk',
      address: 'Nova Park, Quetta',
      categoriesSupplied: ['Syrups', 'Drops', 'Injections'],
      lastOrderDate: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  List<Supplier> get _filteredSuppliers {
    if (_searchQuery.isEmpty) return _suppliers;
    return _suppliers.where((s) {
      final query = _searchQuery.toLowerCase();
      return s.companyName.toLowerCase().contains(query) ||
             s.contactPerson.toLowerCase().contains(query);
    }).toList();
  }

  void _deleteSupplier(String id) {
    setState(() {
      _suppliers.removeWhere((s) => s.id == id);
    });
    // TODO: On delete, remove document from Firestore 'suppliers' collection
  }

  void _openAddEditDialog([Supplier? supplier]) {
    showDialog(
      context: context,
      builder: (context) => _AddEditSupplierDialog(
        supplier: supplier,
        onSave: (savedSupplier) {
          setState(() {
            if (supplier == null) {
              _suppliers.insert(0, savedSupplier);
              // TODO: On save, write to Firestore (add doc)
            } else {
              final index = _suppliers.indexWhere((s) => s.id == savedSupplier.id);
              if (index != -1) {
                _suppliers[index] = savedSupplier;
                // TODO: On save, write to Firestore (update doc)
              }
            }
          });
        },
      ),
    );
  }

  
  void _recordPayment(Supplier c) {
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
            child: _RecordPaymentDialog(supplier: c),
          ),
        );
      },
    );
  }

  void _viewLedger(Supplier c) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Supplier Ledger Dialog',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: _SupplierLedgerDialog(supplier: c),
          ),
        );
      },
    );
  }


  void _confirmDelete(Supplier supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Supplier?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete ${supplier.companyName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSupplier(supplier.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSuppliers;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: ExecutiveHeader(
                    title: 'Suppliers',
                    subtitle: 'Manage your medicine suppliers, track pending balances, and record payments.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Filter Row ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search by company or contact person...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: _primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.business, color: _primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Total Suppliers: ${filtered.length}',
                        style: const TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _openAddEditDialog(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Supplier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Main Content / Table ────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : _buildTable(filtered),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No suppliers found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or add a new supplier.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<Supplier> suppliers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              _headerCell('Company Name', flex: 2),
              _headerCell('Contact Person', flex: 2),
              _headerCell('Contact Info', flex: 2),
              _headerCell('Last Order', flex: 1, textAlign: TextAlign.center),
              const SizedBox(width: 140), // Actions space
            ],
          ),
        ),
        // Table Body
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: suppliers.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              return _SupplierRow(
                supplier: suppliers[index],
                onPayment: () => _recordPayment(suppliers[index]),
                onView: () => _viewLedger(suppliers[index]),
                onEdit: () => _openAddEditDialog(suppliers[index]),
                onDelete: () => _confirmDelete(suppliers[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String title, {int flex = 1, TextAlign? textAlign}) {
    return Expanded(
      flex: flex,
      child: Text(
        title.toUpperCase(),
        textAlign: textAlign,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SupplierRow extends StatefulWidget {
  final Supplier supplier;
  final VoidCallback onPayment;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SupplierRow({
    required this.supplier,
    required this.onPayment,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SupplierRow> createState() => _SupplierRowState();
}

class _SupplierRowState extends State<_SupplierRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.supplier;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: _isHovered ? const Color(0xFFF4F7F6) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                s.companyName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                s.contactPerson,
                style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.phone, style: TextStyle(color: Colors.grey.shade800, fontSize: 13)),
                  if (s.email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(s.email, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                'N/A',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
            SizedBox(
              width: 164,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _isHovered ? 1.0 : 0.0,
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
    );
  }
}

class _AddEditSupplierDialog extends StatefulWidget {
  final Supplier? supplier;
  final ValueChanged<Supplier> onSave;

  const _AddEditSupplierDialog({this.supplier, required this.onSave});

  @override
  State<_AddEditSupplierDialog> createState() => _AddEditSupplierDialogState();
}

class _AddEditSupplierDialogState extends State<_AddEditSupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _companyNameController;
  late TextEditingController _contactPersonController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController(text: widget.supplier?.companyName ?? '');
    _contactPersonController = TextEditingController(text: widget.supplier?.contactPerson ?? '');
    _phoneController = TextEditingController(text: widget.supplier?.phone ?? '');
    _emailController = TextEditingController(text: widget.supplier?.email ?? '');
    _addressController = TextEditingController(text: widget.supplier?.address ?? '');
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final supplier = Supplier(
        id: widget.supplier?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        companyName: _companyNameController.text.trim(),
        phone: _phoneController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        email: '',
        categoriesSupplied: [],
        lastOrderDate: widget.supplier?.lastOrderDate ?? DateTime.now(),
        address: _addressController.text.trim(),
        pendingAmount: widget.supplier?.pendingAmount ?? 0.0,
        advanceAmount: widget.supplier?.advanceAmount ?? 0.0,
      );
      
      Navigator.of(context).pop();
      widget.onSave(supplier);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.supplier != null;

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
                          isEditing ? 'Edit Supplier' : 'Add New Supplier',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E2B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEditing ? 'Update existing supplier details' : 'Create a new supplier profile',
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
                    Text('Capture the supplier name and contact details used across invoices and ledgers.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    const SizedBox(height: 24),
                    
                    _buildField(
                      controller: _companyNameController,
                      label: 'Supplier name',
                      hint: 'e.g. Al-Nafi Traders',
                      validator: (val) => val == null || val.isEmpty ? 'Company Name is required' : null,
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
                      child: Text(isEditing ? 'Save Changes' : 'Add Supplier', style: const TextStyle(fontWeight: FontWeight.w600)),
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
  final double? debit;
  final double? credit;
  final double balance;

  _LedgerEntry(this.date, this.reference, this.description, this.debit, this.credit, this.balance);
}

class _SupplierLedgerDialog extends StatelessWidget {
  final Supplier supplier;

  const _SupplierLedgerDialog({required this.supplier});

  @override
  Widget build(BuildContext context) {
    // Mock ledger entries mimicking the image
    final entries = [
      _LedgerEntry(DateTime(2026, 6, 27), 'INV-1', 'Invoice INV-1', null, 2800, 2800),
      _LedgerEntry(DateTime(2026, 6, 27), 'REC-INV-1', 'Payment received for Invoice INV-1', 2800, null, 0),
      _LedgerEntry(DateTime(2026, 6, 27), 'ADV-INV-1', 'Advance received from supplier after Invoice INV-1', 200, null, -200),
      _LedgerEntry(DateTime(2026, 6, 27), 'SR-1', 'Sales Return SR-1 against INV-1', 224, null, -424),
    ];

    bool isAdvance = supplier.advanceAmount > 0;
    double closingBalance = isAdvance ? supplier.advanceAmount : supplier.pendingAmount;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Container(
        width: 850,
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
                  child: const Icon(Icons.receipt_long, color: Color(0xFF7E57C2), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Supplier Ledger', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E2B))),
                      const SizedBox(height: 4),
                      Text('Financial statement for ${supplier.companyName}', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
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
            // Main Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Supplier Info Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9), // Light green
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_balance_wallet, color: Color(0xFF4CAF50)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(supplier.companyName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E2B))),
                            const SizedBox(height: 2),
                            Text('Supplier statement and running receivable balance.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                            const SizedBox(height: 2),
                            Text(supplier.phone, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isAdvance ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(isAdvance ? 'Advance credit' : 'Pending balance', style: TextStyle(fontSize: 12, color: isAdvance ? Colors.green.shade700 : Colors.red.shade700)),
                            const SizedBox(height: 4),
                            Text('Rs. ${NumberFormat('#,##0').format(closingBalance)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isAdvance ? Colors.green.shade700 : Colors.red.shade700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Summary Boxes
                  Row(
                    children: [
                      Expanded(child: _buildSummaryBox(title: 'Opening balance', value: 'Rs. 0', subtitle: '', bgColor: Colors.blue.shade50, valueColor: Colors.blue.shade700)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSummaryBox(title: 'Closing balance', value: 'Rs. ${NumberFormat('#,##0').format(closingBalance)}', subtitle: isAdvance ? 'Advance credit' : (supplier.pendingAmount > 0 ? 'Pending balance' : 'Cleared'), bgColor: const Color(0xFFE8F5E9), valueColor: Colors.green.shade700)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ledger notes', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              const SizedBox(height: 4),
                              Text('Debits reflect incoming payments. Credits reflect outstanding invoice obligations.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Table Header
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
                  Expanded(flex: 2, child: _headerText('DEBIT (PAID)')),
                  Expanded(flex: 2, child: _headerText('CREDIT (OWED)')),
                  Expanded(flex: 2, child: _headerText('BALANCE')),
                ],
              ),
            ),
            // Table Rows
            SizedBox(
              height: 250,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: entries.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF5F5F5)),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(DateFormat('dd MMM yyyy').format(entry.date), style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
                        Expanded(flex: 2, child: Text(entry.reference, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                        Expanded(flex: 4, child: Text(entry.description, style: TextStyle(fontSize: 13, color: Colors.grey.shade800))),
                        Expanded(flex: 2, child: Text(entry.debit != null ? 'Rs. ${NumberFormat('#,##0').format(entry.debit)}' : '-', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green.shade600))),
                        Expanded(flex: 2, child: Text(entry.credit != null ? 'Rs. ${NumberFormat('#,##0').format(entry.credit)}' : '-', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red.shade500))),
                        Expanded(flex: 2, child: Text('Rs. ${NumberFormat('#,##0').format(entry.balance)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSummaryBox({required String title, required String value, required String subtitle, required Color bgColor, required Color valueColor}) {
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
  final Supplier supplier;

  const _RecordPaymentDialog({required this.supplier});

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
    bool isAdvance = widget.supplier.advanceAmount > 0;
    bool hasPending = widget.supplier.pendingAmount > 0;

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
                        const Text('Receive Supplier Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E2B))),
                        const SizedBox(height: 4),
                        Text('Record payment from ${widget.supplier.companyName}', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
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
                            Text('Rs. ${NumberFormat('#,##0').format(isAdvance ? widget.supplier.advanceAmount : widget.supplier.pendingAmount)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isAdvance ? Colors.green.shade700 : Colors.red.shade700)),
                            const SizedBox(height: 4),
                            Text(isAdvance ? 'This supplier already has advance credit available in the ledger.' : 'This supplier has an outstanding balance.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
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

