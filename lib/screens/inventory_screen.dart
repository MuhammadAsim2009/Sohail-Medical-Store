import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/database_helper.dart';
import '../utils/app_feedback.dart';
import '../widgets/executive_header.dart';

// ---------------------------------------------------------------------------
// THEME
// ---------------------------------------------------------------------------
const _kPrimary = Color(0xFF0F4C81);
const _kBg = Color(0xFFF5F7FA);

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
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await DatabaseHelper.instance.getAllProducts();
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
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
              onPurchase: () => _purchaseStock(p),
            );
          }),
        ],
      ),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────────
  void _showProductDialog({Product? product}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedValue = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: 0.8 + (0.2 * curvedValue),
          child: Opacity(
            opacity: anim1.value,
            child: _ProductFormDialog(
              product: product,
              onSave: (p) async {
                if (product == null) {
                  await DatabaseHelper.instance.insertProduct(p);
                } else {
                  p.id = product.id;
                  await DatabaseHelper.instance.updateProduct(p);
                }
                _loadProducts();
              },
            ),
          ),
        );
      },
    );
  }

  void _viewProduct(Product p) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedValue = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: 0.8 + (0.2 * curvedValue),
          child: Opacity(
            opacity: anim1.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.all(24),
              child: Container(
                width: 440,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40, offset: const Offset(0, 20)),
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF4F46E5), size: 28),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                child: Text('SKU: ${p.sku}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context), 
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                          splashRadius: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _InfoRow('Category',   p.category),
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _InfoRow('Packaging',  p.formattedPackaging),
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _InfoRow('Cost Price', 'Rs. ${p.costPrice.toStringAsFixed(0)}'),
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _InfoRow('Sell Price', 'Rs. ${p.sellPrice.toStringAsFixed(0)}'),
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _InfoRow('Stock',      p.formattedStock),
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _InfoRow('Status',     p.status),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F4C81),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Close Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _purchaseStock(Product p) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedValue = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: 0.85 + (0.15 * curvedValue),
          child: Opacity(
            opacity: anim1.value.clamp(0.0, 1.0),
            child: _PurchaseStockDialog(
              product: p,
              onPurchase: (unitName, qty, costPerUnit) async {
                await DatabaseHelper.instance.purchaseStock(p, unitName, qty, costPerUnit);
                _loadProducts();
              },
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(Product p) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFFFEF2F2), shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 36),
              ),
              const SizedBox(height: 24),
              const Text('Delete Product', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: Color(0xFF1A2E2B))),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete "${p.name}"?\nThis action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (p.id != null) {
                          await DatabaseHelper.instance.deleteProduct(p.id!);
                          _loadProducts();
                        }
                        if (mounted) {
                          Navigator.pop(context);
                          AppFeedback.show(
                            context,
                            '"${p.name}" deleted successfully',
                            type: AppFeedbackType.error,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
  final VoidCallback onPurchase;

  const _ProductRow({
    required this.product,
    required this.isEven,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
    required this.onPurchase,
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
                Text('Threshold ${p.threshold.toStringAsFixed(0)} base units', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
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
                Expanded(
                  child: Text(
                    p.formattedStock,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A2E2B)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
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
            flex: 3,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18, color: Color(0xFF0F4C81)),
                  onPressed: onPurchase,
                  tooltip: 'Purchase Stock',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                const SizedBox(width: 4),
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
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
  final Future<void> Function(Product) onSave;

  const _ProductFormDialog({this.product, required this.onSave});

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _PackagingRow {
  final TextEditingController nameCtrl;
  final TextEditingController containsCtrl;
  
  _PackagingRow(String name, String contains) 
    : nameCtrl = TextEditingController(text: name),
      containsCtrl = TextEditingController(text: contains);
      
  void dispose() {
    nameCtrl.dispose();
    containsCtrl.dispose();
  }
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _skuCtrl;
  late final TextEditingController _nameCtrl;

  // Category and Packaging
  String _selectedCategory = 'Tablet';
  List<_PackagingRow> _pkgRows = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _skuCtrl  = TextEditingController(text: p?.sku ?? '');
    _nameCtrl = TextEditingController(text: p?.name ?? '');

    _selectedCategory = p?.category ?? 'Tablet';
    if (!['Tablet', 'Syrup', 'Sachet', 'Other'].contains(_selectedCategory)) {
      _selectedCategory = 'Other';
    }

    if (p != null && p.packaging.isNotEmpty) {
      _pkgRows = p.packaging.map((u) => _PackagingRow(u.name, u.contains.toString())).toList();
    } else {
      _pkgRows = [_PackagingRow('Tablet', '1')]; // default
    }
  }

  @override
  void dispose() {
    _skuCtrl.dispose();
    _nameCtrl.dispose();
    for (var r in _pkgRows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate packaging
    for (var r in _pkgRows) {
      if (r.nameCtrl.text.trim().isEmpty) return; // simple validation
    }
    
    List<ProductUnit> packaging = _pkgRows.map((r) => ProductUnit(
      name: r.nameCtrl.text.trim(),
      contains: int.tryParse(r.containsCtrl.text.trim()) ?? 1,
    )).toList();

    try {
      await widget.onSave(Product(
        sku:        _skuCtrl.text.trim().toUpperCase(),
        name:       _nameCtrl.text.trim(),
        category:   _selectedCategory,
        packaging:  packaging,
        costPrice:  widget.product?.costPrice ?? 0.0,
        sellPrice:  widget.product?.sellPrice ?? 0.0,
        stock:      widget.product?.stock ?? 0.0,
        threshold:  widget.product?.threshold ?? 10.0,
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('UNIQUE constraint failed')
            ? 'Medicine Code "${_skuCtrl.text.trim().toUpperCase()}" already exists.'
            : 'An error occurred while saving the product.';
        AppFeedback.show(context, msg, type: AppFeedbackType.error);
      }
    }
  }

  Widget _buildCategorySelector() {
    final categories = ['Tablet', 'Syrup', 'Sachet', 'Other'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                  // Auto-setup packaging templates based on category
                  if (cat == 'Tablet') {
                    _pkgRows = [
                      _PackagingRow('Box', '10'),
                      _PackagingRow('Strip', '10'),
                      _PackagingRow('Tablet', '1'),
                    ];
                  } else if (cat == 'Syrup') {
                    _pkgRows = [_PackagingRow('Bottle', '1')];
                  } else if (cat == 'Sachet') {
                    _pkgRows = [
                      _PackagingRow('Box', '30'),
                      _PackagingRow('Sachet', '1'),
                    ];
                  } else {
                    _pkgRows = [_PackagingRow('Unit', '1')];
                  }
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F4C81) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? const Color(0xFF0F4C81) : Colors.grey.shade300),
                ),
                child: Text(cat, style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                )),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPackagingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Packaging Hierarchy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B))),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              for (int i = 0; i < _pkgRows.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      if (i < _pkgRows.length - 1) ...[
                        const Text('1 ', style: TextStyle(fontWeight: FontWeight.w600)),
                        Expanded(
                          child: TextFormField(
                            controller: _pkgRows[i].nameCtrl,
                            onChanged: (v) => setState((){}),
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Unit', isDense: true, filled: true, fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('contains', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                        SizedBox(
                          width: 60,
                          child: TextFormField(
                            controller: _pkgRows[i].containsCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Qty', isDense: true, filled: true, fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_pkgRows[i + 1].nameCtrl.text.isEmpty ? 'Sub-unit' : _pkgRows[i + 1].nameCtrl.text, 
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ] else ...[
                        const Text('Base Unit: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _pkgRows[i].nameCtrl,
                            onChanged: (v) => setState((){}),
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'e.g. Tablet, Bottle', isDense: true, filled: true, fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                            ),
                          ),
                        ),
                      ],
                      if (i < _pkgRows.length - 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                          onPressed: () => setState(() => _pkgRows.removeAt(i)),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.only(left: 12),
                        )
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _pkgRows.insert(0, _PackagingRow('', '10'));
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF0F4C81)),
                    label: const Text('Add Parent Unit', style: TextStyle(color: Color(0xFF0F4C81), fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40, offset: const Offset(0, 20)),
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF4F46E5), size: 28),
                    ),
                    const SizedBox(width: 20),
                    Text(isEdit ? 'Edit Product' : 'Add New Product',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context), 
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                      splashRadius: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 36),
  
                // SKU + Name
                Row(children: [
                  Expanded(child: _Field(label: 'Medicine Code', ctrl: _skuCtrl, hint: 'e.g. P001', validator: _req)),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _Field(label: 'Medicine Name', ctrl: _nameCtrl, hint: 'e.g. Panadol', validator: _req)),
                ]),
                const SizedBox(height: 24),
                
                // Category
                _buildCategorySelector(),
                const SizedBox(height: 24),
  
                // Dynamic Packaging
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _buildPackagingFields(),
                ),
                const SizedBox(height: 40),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4C81),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(isEdit ? 'Save Changes' : 'Add Product',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ), // closes Column
        ), // closes SingleChildScrollView
      ), // closes Form
      ), // closes Container
    ); // closes Dialog
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
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B))),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          validator: validator,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F4C81), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// PURCHASE STOCK DIALOG
// ---------------------------------------------------------------------------
class _PurchaseStockDialog extends StatefulWidget {
  final Product product;
  final Future<void> Function(String unitName, double qty, double costPerUnit) onPurchase;

  const _PurchaseStockDialog({required this.product, required this.onPurchase});

  @override
  State<_PurchaseStockDialog> createState() => _PurchaseStockDialogState();
}

class _PurchaseStockDialogState extends State<_PurchaseStockDialog> {
  late String _selectedUnit;
  final _qtyCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Default to the largest (top-level) unit
    _selectedUnit = widget.product.packaging.isNotEmpty
        ? widget.product.packaging.first.name
        : 'Unit';
    _costCtrl.text = widget.product.costPrice.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  double get _baseUnitQty {
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final multiplier = widget.product.getMultiplier(_selectedUnit);
    return qty * multiplier;
  }

  double get _totalCost {
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final cost = double.tryParse(_costCtrl.text.trim()) ?? 0;
    return qty * cost;
  }

  Future<void> _save() async {
    final qty = double.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= 0) return;
    final cost = double.tryParse(_costCtrl.text.trim()) ?? 0;
    setState(() => _saving = true);
    try {
      await widget.onPurchase(_selectedUnit, qty, cost);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final units = p.packaging.map((u) => u.name).toList();
    final baseUnit = p.packaging.isNotEmpty ? p.packaging.last.name : 'Unit';
    final currentStock = p.formattedStock;
    final previewBase = _baseUnitQty;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 40, offset: const Offset(0, 20)),
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Header band ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(28, 24, 20, 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F4C81), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Purchase Stock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
                        const SizedBox(height: 2),
                        Text(p.name, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    splashRadius: 22,
                  ),
                ],
              ),
            ),

            // ─── Body ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Current stock pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF0369A1)),
                        const SizedBox(width: 8),
                        Text('Current stock: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        Text(currentStock, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0369A1))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Unit dropdown
                  const Text('Purchasing Unit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B))),
                  const SizedBox(height: 8),
                  if (units.isEmpty)
                    Text('No packaging defined. Please edit the product first.', style: TextStyle(color: Colors.red.shade400, fontSize: 13))
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F4C81), width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (v) => setState(() => _selectedUnit = v!),
                    ),
                  const SizedBox(height: 20),

                  // Qty + Cost row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quantity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B))),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _qtyCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => setState((){}),
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'e.g. 5',
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F4C81), width: 1.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Cost per Unit (Rs.)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B))),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _costCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => setState((){}),
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'e.g. 120',
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F4C81), width: 1.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Live preview card
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: previewBase > 0 ? const Color(0xFFF0FDF4) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: previewBase > 0 ? const Color(0xFFBBF7D0) : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Will add to stock:', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                            Text(
                              previewBase > 0 ? '+${previewBase.toInt()} $baseUnit' : '—',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: previewBase > 0 ? const Color(0xFF16A34A) : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Cost:', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                            Text(
                              _totalCost > 0 ? 'Rs. ${_totalCost.toStringAsFixed(0)}' : '—',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _totalCost > 0 ? const Color(0xFF0F4C81) : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _saving || (_qtyCtrl.text.trim().isEmpty) ? null : _save,
                          icon: _saving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_outline_rounded, size: 20),
                          label: Text(_saving ? 'Saving...' : 'Confirm Purchase',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F4C81),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
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
      ),
    );
  }
}



