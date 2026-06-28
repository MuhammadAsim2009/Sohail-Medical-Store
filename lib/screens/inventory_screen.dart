import 'package:flutter/material.dart';
import '../widgets/executive_header.dart';

// ---------------------------------------------------------------------------
// THEME
// ---------------------------------------------------------------------------
const _kPrimary = Color(0xFF0F4C81);
const _kBg = Color(0xFFF5F7FA);

// ---------------------------------------------------------------------------
// MODEL
// ---------------------------------------------------------------------------
class Product {
  String sku;
  String name;
  String unit;        // e.g. 'Kgs', 'Ltr', 'Pcs'
  double costPrice;
  double sellPrice;
  double stock;
  double threshold;   // low-stock threshold
  String category;

  Product({
    required this.sku,
    required this.name,
    required this.unit,
    required this.costPrice,
    required this.sellPrice,
    required this.stock,
    required this.threshold,
    required this.category,
  });

  String get status {
    if (stock <= 0) return 'Out of Stock';
    if (stock <= threshold) return 'Low Stock';
    return 'Healthy';
  }

  double get inventoryValue => costPrice * stock;
}

// ---------------------------------------------------------------------------
// DUMMY DATA
// ---------------------------------------------------------------------------
// TODO: Replace with real-time Firestore stream from 'products' collection
List<Product> _products = [
  Product(sku: 'P001', name: 'Panadol 500mg',       unit: 'Strips', costPrice: 18,  sellPrice: 22,  stock: 340,  threshold: 30, category: 'Tablets'),
  Product(sku: 'P002', name: 'Augmentin 625mg',      unit: 'Strips', costPrice: 320, sellPrice: 380, stock: 85,   threshold: 20, category: 'Tablets'),
  Product(sku: 'P003', name: 'Brufen 400mg',         unit: 'Strips', costPrice: 55,  sellPrice: 70,  stock: 12,   threshold: 20, category: 'Tablets'),
  Product(sku: 'P004', name: 'Omeprazole 20mg',      unit: 'Strips', costPrice: 95,  sellPrice: 120, stock: 200,  threshold: 25, category: 'Capsules'),
  Product(sku: 'P005', name: 'Metformin 500mg',      unit: 'Strips', costPrice: 75,  sellPrice: 95,  stock: 150,  threshold: 20, category: 'Tablets'),
  Product(sku: 'P006', name: 'Amlodipine 5mg',       unit: 'Strips', costPrice: 130, sellPrice: 160, stock: 0,    threshold: 15, category: 'Tablets'),
  Product(sku: 'P007', name: 'Ventolin Inhaler',     unit: 'Pcs',    costPrice: 280, sellPrice: 340, stock: 22,   threshold: 10, category: 'Inhalers'),
  Product(sku: 'P008', name: 'Cofcol Syrup 90ml',    unit: 'Bottles',costPrice: 85,  sellPrice: 110, stock: 60,   threshold: 15, category: 'Syrups'),
  Product(sku: 'P009', name: 'ORS Sachet',           unit: 'Sachets',costPrice: 12,  sellPrice: 18,  stock: 500,  threshold: 50, category: 'Supplements'),
  Product(sku: 'P010', name: 'Disprin 300mg',        unit: 'Strips', costPrice: 20,  sellPrice: 28,  stock: 3,    threshold: 20, category: 'Tablets'),
  Product(sku: 'P011', name: 'Insulin (Humulin N)',  unit: 'Vials',  costPrice: 750, sellPrice: 900, stock: 18,   threshold: 10, category: 'Injections'),
  Product(sku: 'P012', name: 'Flagyl 400mg',         unit: 'Strips', costPrice: 45,  sellPrice: 60,  stock: 0,    threshold: 20, category: 'Tablets'),
  Product(sku: 'P013', name: 'Polyfax Ointment',     unit: 'Tubes',  costPrice: 120, sellPrice: 155, stock: 35,   threshold: 10, category: 'Ointments'),
  Product(sku: 'P014', name: 'Surbex Z',             unit: 'Strips', costPrice: 200, sellPrice: 250, stock: 110,  threshold: 20, category: 'Supplements'),
  Product(sku: 'P015', name: 'Ciplox 500mg',         unit: 'Strips', costPrice: 210, sellPrice: 265, stock: 45,   threshold: 15, category: 'Tablets'),
  Product(sku: 'P016', name: 'Arinac Forte',         unit: 'Strips', costPrice: 65,  sellPrice: 85,  stock: 9,    threshold: 20, category: 'Tablets'),
  Product(sku: 'P017', name: 'Risek 20mg',           unit: 'Strips', costPrice: 180, sellPrice: 220, stock: 90,   threshold: 15, category: 'Capsules'),
  Product(sku: 'P018', name: 'Glucometer Strips',    unit: 'Boxes',  costPrice: 850, sellPrice: 1050,stock: 14,   threshold: 5,  category: 'Diagnostics'),
  Product(sku: 'P019', name: 'Surgical Gloves (M)',  unit: 'Boxes',  costPrice: 380, sellPrice: 480, stock: 28,   threshold: 10, category: 'Surgical'),
  Product(sku: 'P020', name: 'Paediatric Syrup ORS', unit: 'Bottles',costPrice: 65,  sellPrice: 85,  stock: 42,   threshold: 10, category: 'Syrups'),
];

// ---------------------------------------------------------------------------
// INVENTORY SCREEN
// ---------------------------------------------------------------------------
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // ── Computed stats ──────────────────────────────────────────────────────────
  double get _totalInventoryValue  => _products.fold(0.0, (s, p) => s + p.inventoryValue);
  int    get _catalogCount         => _products.length;
  double get _totalStockUnits      => _products.fold(0.0, (s, p) => s + p.stock);
  int    get _riskItemCount        => _products.where((p) => p.status != 'Healthy').length;
  int    get _lowStockCount        => _products.where((p) => p.status == 'Low Stock').length;

  List<Product> get _filtered {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _products;
    return _products.where((p) =>
      p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Format helpers ──────────────────────────────────────────────────────────
  String _fmt(double v) {
    if (v >= 1000) {
      return 'Rs. ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
    return 'Rs. ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;

    return Container(
      color: _kBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Executive Header ───────────────────────────────────────────
            const ExecutiveHeader(
              title: 'Inventory',
              subtitle: 'Monitor stock health, catalog quality, and inventory value from one workspace.',
            ),
            const SizedBox(height: 28),

            // ── 4 Stat Cards ───────────────────────────────────────────────
            _buildStatCards(),
            const SizedBox(height: 20),

            // ── Search + Add Product ────────────────────────────────────────
            _buildSearchBar(),
            const SizedBox(height: 12),

            // ── Filter chips ────────────────────────────────────────────────
            _buildFilterChips(rows.length),
            const SizedBox(height: 0),

            // ── Product Table ───────────────────────────────────────────────
            _buildTable(rows),
          ],
        ),
      ),
    );
  }

  // ── Stat Cards ─────────────────────────────────────────────────────────────
  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(child: _StatCard(
          icon: Icons.inventory_2_outlined,
          iconBg: const Color(0xFFEEF2FF),
          iconColor: const Color(0xFF4F46E5),
          title: 'Inventory value',
          value: _fmt(_totalInventoryValue),
          subtitle: 'Purchase cost basis',
        )),
        const SizedBox(width: 16),
        Expanded(child: _StatCard(
          icon: Icons.category_outlined,
          iconBg: const Color(0xFFE0F2FE),
          iconColor: const Color(0xFF0284C7),
          title: 'Catalog items',
          value: '$_catalogCount',
          subtitle: 'Products currently tracked',
        )),
        const SizedBox(width: 16),
        Expanded(child: _StatCard(
          icon: Icons.bar_chart_rounded,
          iconBg: const Color(0xFFECFDF5),
          iconColor: const Color(0xFF059669),
          title: 'Stock units',
          value: _totalStockUnits.toStringAsFixed(1),
          subtitle: 'Healthy stock posture',
        )),
        const SizedBox(width: 16),
        Expanded(child: _StatCard(
          icon: Icons.warning_amber_rounded,
          iconBg: const Color(0xFFFFFBEB),
          iconColor: const Color(0xFFD97706),
          title: 'Risk items',
          value: '$_riskItemCount',
          subtitle: _riskItemCount == 0 ? 'No stockouts right now' : '$_riskItemCount item(s) need attention',
        )),
      ],
    );
  }

  // ── Search + Add Product ────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Row(
      children: [
        // Search
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: Colors.grey.shade400),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search by product name or sku',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Add Product
        ElevatedButton.icon(
          onPressed: () => _showProductDialog(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // ── Filter chips ────────────────────────────────────────────────────────────
  Widget _buildFilterChips(int visibleCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          left: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          _Chip(icon: Icons.view_module_outlined, label: '$visibleCount visible'),
          const SizedBox(width: 8),
          _Chip(
            icon: Icons.warning_amber_rounded,
            label: '$_lowStockCount low stock',
            color: _lowStockCount > 0 ? Colors.orange : null,
          ),
          const Spacer(),
          Text('Products workspace', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Product Table ──────────────────────────────────────────────────────────
  Widget _buildTable(List<Product> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: const Row(
              children: [
                _TH('SKU',      flex: 2),
                _TH('PRODUCT',  flex: 5),
                _TH('COST',     flex: 2),
                _TH('SELL',     flex: 2),
                _TH('STOCK',    flex: 2),
                _TH('STATUS',   flex: 2),
                _TH('ACTIONS',  flex: 2),
              ],
            ),
          ),

          // Empty state
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No products found', style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('Click "+ Add Product" to add your first product', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                  ],
                ),
              ),
            ),

          // Rows
          ...rows.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            return _ProductRow(
              product: p,
              isEven: i.isEven,
              onEdit: () => _showProductDialog(product: p),
              onDelete: () => _confirmDelete(p),
              onView: () => _viewProduct(p),
            );
          }),
        ],
      ),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────────
  void _showProductDialog({Product? product}) {
    showDialog(
      context: context,
      builder: (_) => _ProductFormDialog(
        product: product,
        onSave: (p) {
          setState(() {
            if (product == null) {
              _products.add(p);
            } else {
              final idx = _products.indexWhere((x) => x.sku == product.sku);
              if (idx != -1) _products[idx] = p;
            }
          });
        },
      ),
    );
  }

  void _viewProduct(Product p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InfoRow('SKU',        p.sku),
            _InfoRow('Category',   p.category),
            _InfoRow('Unit',       p.unit),
            _InfoRow('Cost Price', 'Rs. ${p.costPrice.toStringAsFixed(0)}'),
            _InfoRow('Sell Price', 'Rs. ${p.sellPrice.toStringAsFixed(0)}'),
            _InfoRow('Stock',      '${p.stock} ${p.unit}'),
            _InfoRow('Status',     p.status),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _confirmDelete(Product p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${p.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _products.removeWhere((x) => x.sku == p.sku));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PRODUCT ROW
// ---------------------------------------------------------------------------
class _ProductRow extends StatelessWidget {
  final Product product;
  final bool isEven;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _ProductRow({
    required this.product,
    required this.isEven,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFFAFAFA),
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // SKU badge
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                p.sku,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Product name + threshold
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B))),
                Text('Threshold ${p.threshold.toStringAsFixed(0)} ${p.unit}', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              ],
            ),
          ),

          // Cost
          Expanded(
            flex: 2,
            child: Text('Rs. ${p.costPrice.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          ),

          // Sell (highlighted)
          Expanded(
            flex: 2,
            child: Text('Rs. ${p.sellPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
          ),

          // Stock
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: p.status == 'Healthy' ? Colors.green : p.status == 'Low Stock' ? Colors.orange : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text('${p.stock} ${p.unit}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A2E2B))),
              ],
            ),
          ),

          // Status badge
          Expanded(
            flex: 2,
            child: _StatusBadge(status: p.status),
          ),

          // Actions
          Expanded(
            flex: 2,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.open_in_new_rounded, size: 18, color: Colors.grey.shade500),
                  onPressed: onView,
                  tooltip: 'View',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade500),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade300),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
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
    Color bg, fg;
    switch (status) {
      case 'Healthy':
        bg = const Color(0xFFECFDF5); fg = const Color(0xFF059669);
        break;
      case 'Low Stock':
        bg = const Color(0xFFFFFBEB); fg = const Color(0xFFD97706);
        break;
      default:
        bg = const Color(0xFFFEF2F2); fg = const Color(0xFFDC2626);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

// ---------------------------------------------------------------------------
// STAT CARD
// ---------------------------------------------------------------------------
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                const SizedBox(height: 5),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A2E2B), letterSpacing: -0.5)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FILTER CHIP
// ---------------------------------------------------------------------------
class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _Chip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color != null ? color!.withValues(alpha: 0.08) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color != null ? color!.withValues(alpha: 0.25) : Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TABLE HEADER CELL
// ---------------------------------------------------------------------------
class _TH extends StatelessWidget {
  final String label;
  final int flex;
  const _TH(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5)),
    );
  }
}

// ---------------------------------------------------------------------------
// INFO ROW (view dialog)
// ---------------------------------------------------------------------------
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B))),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PRODUCT FORM DIALOG (Add / Edit)
// ---------------------------------------------------------------------------
class _ProductFormDialog extends StatefulWidget {
  final Product? product;
  final ValueChanged<Product> onSave;

  const _ProductFormDialog({this.product, required this.onSave});

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _skuCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _packagingCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _skuCtrl        = TextEditingController(text: p?.sku ?? '');
    _nameCtrl       = TextEditingController(text: p?.name ?? '');
    _packagingCtrl  = TextEditingController(text: p?.unit ?? '');
  }

  @override
  void dispose() {
    for (final c in [_skuCtrl, _nameCtrl, _packagingCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(Product(
      sku:        _skuCtrl.text.trim().toUpperCase(),
      name:       _nameCtrl.text.trim(),
      category:   widget.product?.category ?? 'General',
      unit:       _packagingCtrl.text.trim(),
      costPrice:  widget.product?.costPrice ?? 0,
      sellPrice:  widget.product?.sellPrice ?? 0,
      stock:      widget.product?.stock ?? 0,
      threshold:  widget.product?.threshold ?? 5,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(28),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF4F46E5), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(isEdit ? 'Edit Product' : 'Add Product',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: Colors.grey.shade400)),
                ],
              ),
              const SizedBox(height: 24),

              // SKU + Name
              Row(children: [
                Expanded(child: _Field(label: 'Medicine code', ctrl: _skuCtrl, hint: 'e.g. P001', validator: _req)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _Field(label: 'Medicine Name', ctrl: _nameCtrl, hint: 'e.g. Panadol 500mg', validator: _req)),
              ]),
              const SizedBox(height: 14),

              // Packaging (Full Width)
              _Field(label: 'Packaging', ctrl: _packagingCtrl, hint: 'e.g. 10x10 strips', validator: _req),
              const SizedBox(height: 28),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(isEdit ? 'Save Changes' : 'Add Product',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
}

// ---------------------------------------------------------------------------
// FORM FIELD HELPER
// ---------------------------------------------------------------------------
class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.ctrl,
    required this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B))),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          validator: validator,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          ),
        ),
      ],
    );
  }
}
