import 'package:flutter/material.dart';

// TODO: Replace local list with real-time Firestore stream from 'suppliers' collection

class Supplier {
  final String id;
  final String companyName;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final List<String> categoriesSupplied;
  final DateTime lastOrderDate;

  Supplier({
    required this.id,
    required this.companyName,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
    required this.categoriesSupplied,
    required this.lastOrderDate,
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
  static const Color _accentColor = Color(0xFF1976D2);
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

  void _openViewDialog(Supplier supplier) {
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
                  const Text('Supplier Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.grey.shade500,
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 24,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Company Name', supplier.companyName),
              _buildDetailRow('Contact Person', supplier.contactPerson),
              _buildDetailRow('Phone Number', supplier.phone),
              _buildDetailRow('Email', supplier.email.isNotEmpty ? supplier.email : '--'),
              _buildDetailRow('Address', supplier.address.isNotEmpty ? supplier.address : '--'),
              _buildDetailRow('Last Order', '${supplier.lastOrderDate.day}/${supplier.lastOrderDate.month}/${supplier.lastOrderDate.year}'),
              const SizedBox(height: 8),
              const Text('Categories Supplied', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: supplier.categoriesSupplied.isEmpty 
                    ? [const Text('--', style: TextStyle(fontWeight: FontWeight.w600))]
                    : supplier.categoriesSupplied.map((cat) => _SmallChip(label: cat)).toList(),
              ),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Suppliers',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2E2B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your medicine suppliers',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _openAddEditDialog(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Supplier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    elevation: 0,
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
                          color: Colors.black.withOpacity(0.04),
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
                    color: _primaryColor.withOpacity(0.1),
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
                const Spacer(flex: 1),
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
                      color: Colors.black.withOpacity(0.03),
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
              _headerCell('Categories', flex: 2),
              _headerCell('Last Order', flex: 1),
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
                onView: () => _openViewDialog(suppliers[index]),
                onEdit: () => _openAddEditDialog(suppliers[index]),
                onDelete: () => _confirmDelete(suppliers[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title.toUpperCase(),
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
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SupplierRow({
    required this.supplier,
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
              flex: 2,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: _buildCategoryChips(s.categoriesSupplied),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${s.lastOrderDate.day}/${s.lastOrderDate.month}/${s.lastOrderDate.year}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
            SizedBox(
              width: 140,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _isHovered ? 1.0 : 0.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 20),
                      color: Colors.green.shade600,
                      onPressed: widget.onView,
                      tooltip: 'View Supplier',
                      splashRadius: 20,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: const Color(0xFF0F4C81),
                      onPressed: widget.onEdit,
                      tooltip: 'Edit Supplier',
                      splashRadius: 20,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red.shade400,
                      onPressed: widget.onDelete,
                      tooltip: 'Delete Supplier',
                      splashRadius: 20,
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

  List<Widget> _buildCategoryChips(List<String> categories) {
    if (categories.isEmpty) return [const Text('-')];
    
    List<Widget> chips = [];
    int maxToShow = 2;
    for (int i = 0; i < categories.length && i < maxToShow; i++) {
      chips.add(_SmallChip(label: categories[i]));
    }
    
    if (categories.length > maxToShow) {
      chips.add(_SmallChip(label: '+${categories.length - maxToShow}'));
    }
    
    return chips;
  }
}

class _SmallChip extends StatelessWidget {
  final String label;

  const _SmallChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F4C81).withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF0F4C81).withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F4C81),
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

  final List<String> _availableCategories = [
    'Tablets', 'Syrups', 'Injections', 'Capsules', 'Ointments', 'Drops', 'First Aid', 'Vitamins', 'Supplements'
  ];
  List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    final s = widget.supplier;
    _companyNameController = TextEditingController(text: s?.companyName ?? '');
    _contactPersonController = TextEditingController(text: s?.contactPerson ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    _addressController = TextEditingController(text: s?.address ?? '');
    if (s != null) {
      _selectedCategories = List.from(s.categoriesSupplied);
    }
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

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newSupplier = Supplier(
        id: widget.supplier?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        companyName: _companyNameController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        categoriesSupplied: _selectedCategories,
        lastOrderDate: widget.supplier?.lastOrderDate ?? DateTime.now(),
      );
      widget.onSave(newSupplier);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.supplier != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Supplier' : 'Add Supplier',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                _buildTextField('Company Name *', _companyNameController, required: true),
                const SizedBox(height: 16),
                _buildTextField('Contact Person *', _contactPersonController, required: true),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Phone Number *', _phoneController, required: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Email', _emailController, required: false, isEmail: true)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField('Address', _addressController, maxLines: 2),
                const SizedBox(height: 24),
                const Text('Categories Supplied', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableCategories.map((cat) {
                    final isSelected = _selectedCategories.contains(cat);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedCategories.remove(cat);
                          } else {
                            _selectedCategories.add(cat);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0F4C81) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0F4C81) : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4C81),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    bool isEmail = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              borderSide: const BorderSide(color: Color(0xFF0F4C81), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (required && (value == null || value.trim().isEmpty)) {
              return 'This field is required';
            }
            if (isEmail && value != null && value.trim().isNotEmpty) {
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(value)) {
                return 'Enter a valid email';
              }
            }
            return null;
          },
        ),
      ],
    );
  }
}
