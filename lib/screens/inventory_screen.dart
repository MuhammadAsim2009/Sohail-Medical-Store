import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// MODELS
// ---------------------------------------------------------------------------
class Medicine {
  String id;
  String name;
  String category;
  String batchNo;
  int quantity;
  double unitPrice;
  DateTime expiryDate;

  Medicine({
    required this.id,
    required this.name,
    required this.category,
    required this.batchNo,
    required this.quantity,
    required this.unitPrice,
    required this.expiryDate,
  });
}

// ---------------------------------------------------------------------------
// INVENTORY SCREEN
// ---------------------------------------------------------------------------
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // TODO: Replace local list with real-time Firestore stream from 'medicines' collection
  List<Medicine> _medicines = [];

  String _searchQuery = '';
  String _selectedCategory = 'All Categories';
  String _selectedStatus = 'All';

  final List<String> _categories = [
    'All Categories',
    'Tablets',
    'Syrups',
    'Injections',
    'Capsules',
    'Ointments'
  ];
  
  final List<String> _statuses = [
    'All',
    'In Stock',
    'Low Stock',
    'Out of Stock'
  ];

  @override
  void initState() {
    super.initState();
    _loadDummyData();
  }

  void _loadDummyData() {
    _medicines = [
      Medicine(id: '1', name: 'Panadol 500mg', category: 'Tablets', batchNo: 'B-101', quantity: 150, unitPrice: 2.5, expiryDate: DateTime(2027, 5, 12)),
      Medicine(id: '2', name: 'Augmentin 625mg', category: 'Tablets', batchNo: 'B-102', quantity: 45, unitPrice: 18.0, expiryDate: DateTime(2026, 12, 1)),
      Medicine(id: '3', name: 'Brufen 400mg', category: 'Tablets', batchNo: 'B-103', quantity: 12, unitPrice: 4.0, expiryDate: DateTime(2025, 8, 20)),
      Medicine(id: '4', name: 'Surbex Z', category: 'Tablets', batchNo: 'B-104', quantity: 80, unitPrice: 12.0, expiryDate: DateTime(2028, 1, 15)),
      Medicine(id: '5', name: 'Cofcol', category: 'Syrups', batchNo: 'B-105', quantity: 0, unitPrice: 65.0, expiryDate: DateTime(2026, 6, 30)), // Out of stock
      Medicine(id: '6', name: 'Arinac', category: 'Tablets', batchNo: 'B-106', quantity: 25, unitPrice: 3.5, expiryDate: DateTime(2026, 7, 10)), // Expiring soon
      Medicine(id: '7', name: 'Insulin', category: 'Injections', batchNo: 'B-107', quantity: 8, unitPrice: 850.0, expiryDate: DateTime(2027, 2, 28)),
      Medicine(id: '8', name: 'Polyfax', category: 'Ointments', batchNo: 'B-108', quantity: 30, unitPrice: 45.0, expiryDate: DateTime(2028, 11, 5)),
      Medicine(id: '9', name: 'Omeprazole 20mg', category: 'Capsules', batchNo: 'B-109', quantity: 200, unitPrice: 5.5, expiryDate: DateTime(2027, 9, 14)),
      Medicine(id: '10', name: 'Flagyl 400mg', category: 'Tablets', batchNo: 'B-110', quantity: 0, unitPrice: 2.0, expiryDate: DateTime(2026, 10, 5)), // Out of stock
    ];
  }

  String _getStatus(int quantity) {
    if (quantity == 0) return 'Out of Stock';
    if (quantity <= 20) return 'Low Stock';
    return 'In Stock';
  }

  List<Medicine> get _filteredMedicines {
    return _medicines.where((med) {
      final matchesSearch = med.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            med.batchNo.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All Categories' || med.category == _selectedCategory;
      final matchesStatus = _selectedStatus == 'All' || _getStatus(med.quantity) == _selectedStatus;
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  void _openAddEditDialog([Medicine? medicine]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MedicineFormDialog(
        medicine: medicine,
        categories: _categories.where((c) => c != 'All Categories').toList(),
        onSave: (savedMed) {
          setState(() {
            if (medicine == null) {
              // Add
              // TODO: On save, write to Firestore instead of updating local list
              _medicines.add(savedMed);
            } else {
              // Edit
              // TODO: On save, update Firestore instead of local list
              final index = _medicines.indexWhere((m) => m.id == savedMed.id);
              if (index != -1) {
                _medicines[index] = savedMed;
              }
            }
          });
        },
      ),
    );
  }

  void _confirmDelete(Medicine medicine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete ${medicine.name}?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: On delete, remove document from Firestore 'medicines' collection
              setState(() {
                _medicines.removeWhere((m) => m.id == medicine.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${medicine.name} deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredMedicines;

    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Row ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inventory',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A2E2B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your medicine stock',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _openAddEditDialog(),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Medicine'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4C81),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Filter Bar ──────────────────────────────────────────────
          Row(
            children: [
              // Search
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search medicine or batch...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Category Filter
              Expanded(
                flex: 1,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                      style: const TextStyle(color: Color(0xFF1A2E2B), fontSize: 14, fontWeight: FontWeight.w500),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Status Filter
              Expanded(
                flex: 1,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                      style: const TextStyle(color: Color(0xFF1A2E2B), fontSize: 14, fontWeight: FontWeight.w500),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatus = val);
                      },
                      items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Data Table ──────────────────────────────────────────────
          Expanded(
            child: Container(
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
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: filteredList.isEmpty
                  ? Center(
                      child: Text(
                        'No medicines found.',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFA)),
                          dataRowMinHeight: 56,
                          dataRowMaxHeight: 56,
                          horizontalMargin: 24,
                          columnSpacing: 32,
                          columns: const [
                            DataColumn(label: Text('Medicine Name', style: TextStyle(fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Batch No.', style: TextStyle(fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Expiry Date', style: TextStyle(fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
                          ],
                          rows: filteredList.map((med) {
                            final status = _getStatus(med.quantity);
                            return DataRow(
                              cells: [
                                DataCell(Text(med.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                                DataCell(Text(med.category, style: TextStyle(color: Colors.grey.shade700))),
                                DataCell(Text(med.batchNo, style: TextStyle(color: Colors.grey.shade700))),
                                DataCell(Text('${med.quantity}', style: const TextStyle(fontWeight: FontWeight.w500))),
                                DataCell(Text('Rs. ${med.unitPrice.toStringAsFixed(2)}')),
                                DataCell(Text(DateFormat('dd MMM yyyy').format(med.expiryDate))),
                                DataCell(_StatusBadge(status: status)),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20),
                                        color: const Color(0xFF0F4C81),
                                        tooltip: 'Edit',
                                        onPressed: () => _openAddEditDialog(med),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20),
                                        color: Colors.red.shade300,
                                        tooltip: 'Delete',
                                        onPressed: () => _confirmDelete(med),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    );
                  }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STATUS BADGE
// ---------------------------------------------------------------------------
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'In Stock':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'Low Stock':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        break;
      case 'Out of Stock':
      default:
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ADD / EDIT DIALOG
// ---------------------------------------------------------------------------
class _MedicineFormDialog extends StatefulWidget {
  final Medicine? medicine;
  final List<String> categories;
  final ValueChanged<Medicine> onSave;

  const _MedicineFormDialog({this.medicine, required this.categories, required this.onSave});

  @override
  State<_MedicineFormDialog> createState() => _MedicineFormDialogState();
}

class _MedicineFormDialogState extends State<_MedicineFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _batchCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;
  
  String? _selectedCategory;
  DateTime? _selectedExpiry;

  @override
  void initState() {
    super.initState();
    final med = widget.medicine;
    _nameCtrl = TextEditingController(text: med?.name ?? '');
    _batchCtrl = TextEditingController(text: med?.batchNo ?? '');
    _qtyCtrl = TextEditingController(text: med?.quantity.toString() ?? '');
    _priceCtrl = TextEditingController(text: med?.unitPrice.toString() ?? '');
    
    _selectedCategory = med?.category ?? (widget.categories.isNotEmpty ? widget.categories.first : null);
    _selectedExpiry = med?.expiryDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _batchCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _pickExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedExpiry ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2050),
    );
    if (date != null) {
      setState(() => _selectedExpiry = date);
    }
  }

  void _save() {
    if (_formKey.currentState!.validate() && _selectedExpiry != null && _selectedCategory != null) {
      final newMed = Medicine(
        id: widget.medicine?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameCtrl.text.trim(),
        category: _selectedCategory!,
        batchNo: _batchCtrl.text.trim(),
        quantity: int.parse(_qtyCtrl.text.trim()),
        unitPrice: double.parse(_priceCtrl.text.trim()),
        expiryDate: _selectedExpiry!,
      );
      widget.onSave(newMed);
      Navigator.pop(context);
    } else if (_selectedExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an expiry date.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.medicine != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'Edit Medicine' : 'Add Medicine',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E2B)),
              ),
              const SizedBox(height: 24),
              
              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Medicine Name', hintText: 'e.g. Panadol 500mg'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              // Category & Batch
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: widget.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                      validator: (val) => val == null ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _batchCtrl,
                      decoration: const InputDecoration(labelText: 'Batch Number', hintText: 'e.g. B-123'),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Quantity & Price
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        final num = int.tryParse(val);
                        if (num == null || num < 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Unit Price (Rs.)'),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        final num = double.tryParse(val);
                        if (num == null || num <= 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Expiry Date
              InkWell(
                onTap: _pickExpiryDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Expiry Date',
                    errorText: _selectedExpiry == null ? 'Required' : null,
                    suffixIcon: const Icon(Icons.calendar_today, size: 20),
                  ),
                  child: Text(
                    _selectedExpiry == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(_selectedExpiry!),
                    style: TextStyle(color: _selectedExpiry == null ? Colors.grey.shade600 : Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C81),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
