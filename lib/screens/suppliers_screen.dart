import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/executive_header.dart';
import '../models/supplier.dart';
import '../models/purchase_order.dart';
import '../models/supplier_payment.dart';
import '../services/database_helper.dart';
import '../utils/app_feedback.dart';

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
  List<Supplier> _suppliers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    final suppliers = await DatabaseHelper.instance.getSuppliers();
    setState(() {
      _suppliers = suppliers;
      _isLoading = false;
    });
  }

  List<Supplier> get _filteredSuppliers {
    if (_searchQuery.isEmpty) return _suppliers;
    return _suppliers.where((s) {
      final query = _searchQuery.toLowerCase();
      return s.companyName.toLowerCase().contains(query) ||
             s.contactPerson.toLowerCase().contains(query);
    }).toList();
  }

  void _deleteSupplier(String id) async {
    await DatabaseHelper.instance.deleteSupplier(id);
    _loadSuppliers();
  }

  void _openAddEditDialog([Supplier? supplier]) {
    showDialog(
      context: context,
      builder: (context) => _AddEditSupplierDialog(
        supplier: supplier,
        onSave: (savedSupplier) async {
          if (supplier == null) {
            await DatabaseHelper.instance.insertSupplier(savedSupplier);
          } else {
            await DatabaseHelper.instance.updateSupplier(savedSupplier);
          }
          _loadSuppliers();
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
    ).then((saved) {
      if (saved == true) {
        _loadSuppliers();
      }
    });
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
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
              _headerCell('Balance', flex: 1, textAlign: TextAlign.center),
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
              child: Builder(
                builder: (context) {
                  final double balance = s.advanceAmount - s.pendingAmount;
                  final bool isPositive = balance >= 0;
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isPositive ? Colors.green.shade200 : Colors.red.shade200),
                      ),
                      child: Text(
                        '${isPositive ? '+' : '-'}Rs ${balance.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }
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
        child: SingleChildScrollView(
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
                      controller: _contactPersonController,
                      label: 'Contact person',
                      hint: 'e.g. Ali Khan',
                      validator: (val) => val == null || val.isEmpty ? 'Contact Person is required' : null,
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

class _SupplierLedgerDialog extends StatefulWidget {
  final Supplier supplier;

  const _SupplierLedgerDialog({required this.supplier});

  @override
  State<_SupplierLedgerDialog> createState() => _SupplierLedgerDialogState();
}

class _SupplierLedgerDialogState extends State<_SupplierLedgerDialog> {
  late final Future<List<_LedgerEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _loadEntries();
  }

  Future<List<_LedgerEntry>> _loadEntries() async {
    final supplierId = widget.supplier.id;
    if (supplierId.isEmpty) {
      return [];
    }

    final rows = await DatabaseHelper.instance.getSupplierStatement(supplierId, null, null);
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
    return widget.supplier.advanceAmount - widget.supplier.pendingAmount;
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
            final hasAdvance = closingBalance > 0;
            final balanceLabel = hasAdvance ? 'Advance credit' : (closingBalance < 0 ? 'Pending balance' : 'Cleared');
            final balanceColor = hasAdvance ? Colors.green.shade700 : (closingBalance < 0 ? Colors.red.shade700 : Colors.grey.shade600);
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
                    'Failed to load supplier ledger',
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
                              'Supplier Ledger',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E2B)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Financial statement for ${widget.supplier.companyName}',
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
                                    widget.supplier.companyName,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E2B)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Live supplier statement and running payable balance.',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(widget.supplier.phone, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
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
                                  Text(balanceLabel, style: TextStyle(fontSize: 12, color: balanceColor)),
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
                                subtitle: 'Invoices and charges billed',
                                bgColor: Colors.red.shade50,
                                valueColor: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSummaryBox(
                                title: 'Total credit',
                                value: 'Rs. ${NumberFormat('#,##0').format(totalCredit)}',
                                subtitle: 'Payments and advances applied',
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
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '0');
  final _receiptController = TextEditingController();
  final _notesController = TextEditingController();
    bool _isGeneralReceipt = true;
    List<PurchaseOrder> _availableInvoices = [];
  String? _selectedInvoiceNumber;

  @override
  void initState() {
    super.initState();
    _receiptController.text = 'PAY-CUST-${DateTime.now().millisecondsSinceEpoch}';
    _loadInvoices();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _receiptController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    final orders = await DatabaseHelper.instance.getAllPurchaseOrders();
    final invoices = orders
        .where((order) => order.supplier == widget.supplier.companyName && order.balance > 0)
        .toList()
      ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
    if (!mounted) return;
    setState(() {
      _availableInvoices = invoices;
      if (_availableInvoices.isNotEmpty) {
        _isGeneralReceipt = false;
        _selectedInvoiceNumber = _availableInvoices.first.poNumber;
        _amountController.text = _availableInvoices.first.balance.toStringAsFixed(0);
      }
    });
  }

  void _syncSelectedInvoice(String? poNumber) {
    setState(() {
      _selectedInvoiceNumber = poNumber;
      PurchaseOrder? selected;
      for (final order in _availableInvoices) {
        if (order.poNumber == poNumber) {
          selected = order;
          break;
        }
      }
      if (selected != null) {
        _amountController.text = selected.balance.toStringAsFixed(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double netBalance = widget.supplier.advanceAmount - widget.supplier.pendingAmount;
    final bool isAdvance = netBalance > 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                if (netBalance != 0)
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
                              Text(
                                netBalance == 0
                                    ? 'Cleared'
                                    : (isAdvance ? 'Advance credit' : 'Pending balance'),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rs. ${NumberFormat('#,##0').format(netBalance.abs())}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: netBalance == 0 ? Colors.grey.shade700 : (isAdvance ? Colors.green.shade700 : Colors.red.shade700),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                netBalance == 0
                                    ? 'This supplier ledger is fully cleared.'
                                    : (isAdvance
                                        ? 'This supplier already has advance credit available in the ledger.'
                                        : 'This supplier has an outstanding balance.'),
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
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
                      Text(
                        _availableInvoices.isEmpty
                            ? 'No open purchase orders found for this supplier. You can still record a general receipt.'
                            : 'Select an open purchase order or record a general receipt.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      if (_availableInvoices.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: _selectedInvoiceNumber,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Apply to purchase order',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _availableInvoices
                              .map((order) => DropdownMenuItem<String>(
                                    value: order.poNumber,
                                    child: Text('${order.poNumber}  •  Rs. ${order.balance.toStringAsFixed(0)} due', overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _syncSelectedInvoice(value);
                              setState(() => _isGeneralReceipt = false);
                            }
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Amount Section
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payment Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E2B))),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Amount is required';
                          if ((double.tryParse(val) ?? 0) <= 0) return 'Amount must be greater than 0';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Amount (Rs.)',
                          prefixText: 'Rs. ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7E57C2), width: 1.5)),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
                          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _receiptController,
                        decoration: InputDecoration(
                          labelText: 'Receipt / Reference Number',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7E57C2), width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Notes (optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7E57C2), width: 1.5)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
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
                        if (!_formKey.currentState!.validate()) return;
                        final amount = double.tryParse(_amountController.text) ?? 0;
                        if (amount <= 0) return;

                        final payment = SupplierPayment(
                          supplierId: widget.supplier.id,
                          amount: amount,
                          reference: _receiptController.text.trim(),
                          notes: _notesController.text.trim(),
                          date: DateTime.now().toIso8601String(),
                          invoiceNumber: _isGeneralReceipt ? null : _selectedInvoiceNumber,
                        );
                        await DatabaseHelper.instance.insertSupplierPayment(payment);

                        // Update supplier advance/pending
                        final updatedSupplier = widget.supplier.copyWith(
                          advanceAmount: widget.supplier.advanceAmount + amount,
                        );
                        await DatabaseHelper.instance.updateSupplier(updatedSupplier);

                        if (context.mounted) {
                          Navigator.of(context).pop(true);
                          AppFeedback.show(context, 'Payment of Rs. ${amount.toStringAsFixed(0)} recorded', type: AppFeedbackType.success);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7E57C2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      child: const Text('Record Payment'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
