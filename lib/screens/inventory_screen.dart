import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
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

          // ── Product Table ───────────────────────────────────────────────
          Expanded(child: _buildTable(rows)),
        ],
      ),
    );
  }

  // ── CSV Bulk Import ────────────────────────────────────────────────────────
  Future<void> _downloadCsvTemplate() async {
    try {
      final List<List<dynamic>> rows = [
        ['Product Code', 'Product Name', 'Category', 'Packaging (e.g. 14x2)'],
        ['P001', 'Sample Product', 'Medicine', '14x2']
      ];
      String csv = ListToCsvConverter().convert(rows);
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV Template',
        fileName: 'inventory_template.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(csv);
        if (mounted) AppFeedback.show(context, 'Template saved to $outputFile');
      }
    } catch (e) {
      if (mounted) AppFeedback.show(context, 'Failed to save template: $e', type: AppFeedbackType.error);
    }
  }

  Future<void> _importCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final csvString = await file.readAsString();
        final List<List<dynamic>> rows = CsvToListConverter().convert(csvString);
        if (rows.isEmpty || rows.length == 1) {
           if (mounted) AppFeedback.show(context, 'CSV is empty or missing data', type: AppFeedbackType.error);
           return;
        }

        int added = 0;
        final categories = await DatabaseHelper.instance.getCategories();
        
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          if (row.length < 3) continue;

          String sku = row[0].toString().trim();
          String name = row[1].toString().trim();
          String category = row[2].toString().trim();
          String packagingCsv = row.length > 3 ? row[3].toString().trim() : '';
          
          // Default values since they are not in the CSV template
          double costPrice = 0.0;
          double sellPrice = 0.0;
          double stock = 0.0;
          double threshold = 10.0;
          
          if (sku.isEmpty || name.isEmpty) continue;

          List<ProductUnit> packaging = [];
          if (category.isNotEmpty) {
             final catData = categories.firstWhere(
                (c) => c['name'].toString().toLowerCase() == category.toLowerCase(),
                orElse: () => <String, dynamic>{},
             );
             if (catData.isNotEmpty) {
                final pkgJson = catData['packaging'] as String?;
                if (pkgJson != null && pkgJson.isNotEmpty) {
                  try {
                    final List<dynamic> parsed = jsonDecode(pkgJson);
                    packaging = parsed.map((item) => ProductUnit.fromMap(item as Map<String, dynamic>)).toList();
                    
                    if (packagingCsv.isNotEmpty && packaging.length > 1) {
                      final parts = packagingCsv.toLowerCase().split('x').map((s) => int.tryParse(s.trim()) ?? 1).toList();
                      for (int j = 0; j < parts.length; j++) {
                        int unitIndex = packaging.length - 2 - j;
                        if (unitIndex >= 0) {
                          packaging[unitIndex] = ProductUnit(name: packaging[unitIndex].name, contains: parts[j]);
                        }
                      }
                    }
                  } catch (_) {}
                }
             }
          }

          final p = Product(
            sku: sku,
            name: name,
            category: category,
            costPrice: costPrice,
            sellPrice: sellPrice,
            stock: stock,
            threshold: threshold,
            packaging: packaging,
          );
          try {
             await DatabaseHelper.instance.insertProduct(p);
             added++;
          } catch(e) {
             // Silently ignore duplicates for bulk import
          }
        }
        if (mounted) {
           AppFeedback.show(context, 'Successfully imported $added products!');
           _loadProducts();
        }
      }
    } catch (e) {
      if (mounted) AppFeedback.show(context, 'Failed to import CSV: $e', type: AppFeedbackType.error);
    }
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
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                    decoration: const InputDecoration(
                      hintText: 'Search by product name or sku',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 15, fontWeight: FontWeight.w400),
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
        const SizedBox(width: 16),

        // Manage Categories
        OutlinedButton.icon(
          onPressed: () {
            showDialog(context: context, builder: (_) => _CategoryManagerDialog());
          },
          icon: const Icon(Icons.category_outlined, size: 20),
          label: const Text('Categories', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.3)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF475569),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 12),
        // Add Product
        ElevatedButton.icon(
          onPressed: () => _showProductDialog(),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.3)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ).copyWith(
            overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        const SizedBox(width: 8),
        // Bulk Actions
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'download') {
                _downloadCsvTemplate();
              } else if (value == 'import') {
                _importCsv();
              }
            },
            tooltip: 'Bulk Actions',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF475569)),
            offset: const Offset(0, 48),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download_rounded, size: 20, color: Color(0xFF475569)),
                    SizedBox(width: 12),
                    Text('Download CSV Template', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload_file_rounded, size: 20, color: Color(0xFF475569)),
                    SizedBox(width: 12),
                    Text('Import from CSV', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Filter chips ────────────────────────────────────────────────────────────
  Widget _buildFilterChips(int visibleCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          _Chip(icon: Icons.view_module_rounded, label: '$visibleCount visible'),
          const SizedBox(width: 8),
          _Chip(
            icon: Icons.warning_amber_rounded,
            label: '$_lowStockCount low stock',
            color: _lowStockCount > 0 ? const Color(0xFFF59E0B) : null,
          ),
          const Spacer(),
          const Text('Products workspace', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, letterSpacing: 0.2)),
        ],
      ),
    );
  }

  // ── Product Table ──────────────────────────────────────────────────────────
  Widget _buildTable(List<Product> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildFilterChips(rows.length),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
            )
          else
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final p = rows[index];
                  return _ProductRow(
                    product: p,
                    isEven: index.isEven,
                    onEdit: () => _showProductDialog(product: p),
                    onDelete: () => _confirmDelete(p),
                    onView: () => _viewProduct(p),
                  );
                },
              ),
            ),
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
      barrierColor: Colors.black.withValues(alpha: 0.4),
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
      barrierColor: Colors.black.withValues(alpha: 0.4),
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
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 20)),
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
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
                            boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))],
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
        color: isEven ? Colors.white : const Color(0xFFF8FAFC),
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          // SKU badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.sku,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5), letterSpacing: 0.5),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Product name + threshold
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                Text('Threshold ${p.threshold.toStringAsFixed(0)} base units', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),

          // Cost
          Expanded(
            flex: 2,
            child: Text('Rs. ${p.costPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
          ),

          // Sell (highlighted)
          Expanded(
            flex: 2,
            child: Text('Rs. ${p.sellPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
          ),

          // Stock
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: p.status == 'Healthy' ? const Color(0xFF10B981) : p.status == 'Low Stock' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.formattedStock,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
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
            flex: 2,
            child: Row(
              children: [
                IconButton(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF64748B)),
                  tooltip: 'View',
                  splashRadius: 20,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                  tooltip: 'Edit',
                  splashRadius: 20,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                  tooltip: 'Delete',
                  splashRadius: 20,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}




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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: 0.1), width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
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
    final c = color ?? const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color != null ? color!.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, color: c, fontWeight: FontWeight.w600)),
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
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.5)),
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

  // Category
  String? _selectedCategory;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCats = true;
  List<_PackagingRow> _productPkgRows = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _skuCtrl  = TextEditingController(text: p?.sku ?? '');
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _loadCategories(p?.category);
  }

  void _updateProductPkgRows(String categoryName) {
    for (var r in _productPkgRows) { r.dispose(); }
    _productPkgRows.clear();

    final catData = _categories.firstWhere(
      (c) => c['name'] == categoryName,
      orElse: () => {},
    );
    if (catData.isNotEmpty) {
      final pkgJson = catData['packaging'] as String?;
      if (pkgJson != null && pkgJson.isNotEmpty) {
        try {
          final List<dynamic> parsed = jsonDecode(pkgJson);
          final units = parsed.map((item) => ProductUnit.fromMap(item as Map<String, dynamic>)).toList();
          
          for (int i = 0; i < units.length; i++) {
            int existingContains = 1;
            if (widget.product != null && widget.product!.packaging.isNotEmpty) {
              final existingUnit = widget.product!.packaging.firstWhere((u) => u.name == units[i].name, orElse: () => ProductUnit(name: '', contains: 1));
              if (existingUnit.name.isNotEmpty) {
                existingContains = existingUnit.contains;
              }
            }
            _productPkgRows.add(_PackagingRow(units[i].name, existingContains.toString()));
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _loadCategories(String? defaultCat) async {
    final cats = await DatabaseHelper.instance.getCategories();
    setState(() {
      _categories = cats;
      _isLoadingCats = false;
      
      if (_categories.isNotEmpty) {
        if (defaultCat != null && _categories.any((c) => c['name'] == defaultCat)) {
          _selectedCategory = defaultCat;
        } else {
          _selectedCategory = _categories.first['name'] as String;
        }
        _updateProductPkgRows(_selectedCategory!);
      }
    });
  }

  @override
  void dispose() {
    _skuCtrl.dispose();
    _nameCtrl.dispose();
    for (var r in _productPkgRows) { r.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    List<ProductUnit> packaging = _productPkgRows.map((r) => ProductUnit(
      name: r.nameCtrl.text.trim(),
      contains: int.tryParse(r.containsCtrl.text.trim()) ?? 1,
    )).toList();

    try {
      await widget.onSave(Product(
        sku:        _skuCtrl.text.trim().toUpperCase(),
        name:       _nameCtrl.text.trim(),
        category:   _selectedCategory ?? '',
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
    if (_isLoadingCats) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_categories.isEmpty) {
      return const Text('No categories available. Please add categories first.', style: TextStyle(color: Colors.red));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569), letterSpacing: 0.2)),
        const SizedBox(height: 8),
        Autocomplete<String>(
          initialValue: _selectedCategory != null ? TextEditingValue(text: _selectedCategory!) : TextEditingValue.empty,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return _categories.map((c) => c['name'] as String);
            }
            return _categories.map((c) => c['name'] as String).where((String option) {
              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String val) {
            setState(() {
              _selectedCategory = val;
              _updateProductPkgRows(val);
            });
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF4F46E5), width: 2)),
                filled: true,
                fillColor: Color(0xFFF8FAFC),
                hintText: 'Search Category',
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250, maxWidth: 300),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(option),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPackagingEditor() {
    if (_productPkgRows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Packaging Quantities', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569), letterSpacing: 0.2)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < _productPkgRows.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i < _productPkgRows.length - 1 ? 8 : 0),
                  child: Row(
                    children: [
                      if (i < _productPkgRows.length - 1) ...[
                        const Text('1 ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A))),
                        Expanded(child: Text(_productPkgRows[i].nameCtrl.text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)))),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('contains', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w600))),
                        SizedBox(width: 80, child: TextField(
                          controller: _productPkgRows[i].containsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Qty',
                            isDense: true, filled: true, fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                          ),
                          style: const TextStyle(fontSize: 13),
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_productPkgRows[i + 1].nameCtrl.text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)))),
                      ] else ...[
                        Text('Base Unit: ${_productPkgRows[i].nameCtrl.text}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                      ],
                    ],
                  ),
                ),
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 20)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
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
                        boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))],
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
                
                // Packaging Editor
                _buildPackagingEditor(),
                const SizedBox(height: 24),


              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 15)),
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
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569), letterSpacing: 0.2)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444))),
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


// ---------------------------------------------------------------------------
// CATEGORY MANAGER DIALOG
// ---------------------------------------------------------------------------
class _CategoryManagerDialog extends StatefulWidget {
  const _CategoryManagerDialog();

  @override
  State<_CategoryManagerDialog> createState() => _CategoryManagerDialogState();
}

class _CategoryManagerDialogState extends State<_CategoryManagerDialog> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  bool _isAdding = false;

  final _nameCtrl = TextEditingController();
  List<_PackagingRow> _pkgRows = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _pkgRows = [_PackagingRow('Unit', '1')];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (var r in _pkgRows) { r.dispose(); }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await DatabaseHelper.instance.getCategories();
    if (mounted) setState(() { _categories = cats; _isLoading = false; });
  }

  Future<void> _addCategory() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    
    // Check if category name already exists
    if (_categories.any((c) => c['name'].toString().toLowerCase() == name.toLowerCase())) {
      AppFeedback.show(context, 'Category "$name" already exists.', type: AppFeedbackType.error);
      return;
    }
    
    final pkgJson = jsonEncode(_pkgRows.map((r) => {
      'name': r.nameCtrl.text.trim(),
      'contains': 1,
    }).toList());
    try {
      await DatabaseHelper.instance.insertCategory(name, pkgJson);
      _nameCtrl.clear();
      setState(() {
        _pkgRows = [_PackagingRow('Unit', '1')];
        _isAdding = false;
      });
      _loadCategories();
      if (mounted) AppFeedback.show(context, 'Category "$name" added.', type: AppFeedbackType.success);
    } catch (e) {
      if (mounted) AppFeedback.show(context, 'Error adding category.', type: AppFeedbackType.error);
    }
  }

  Future<void> _deleteCategory(Map<String, dynamic> cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${cat['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteCategory(cat['id'] as int);
      _loadCategories();
    }
  }

  Widget _buildPackagingEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Packaging Hierarchy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569), letterSpacing: 0.2)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < _pkgRows.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      if (i < _pkgRows.length - 1) ...[
                        const Text('Parent: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                        Expanded(child: TextField(
                          controller: _pkgRows[i].nameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Box, Strip',
                            isDense: true, filled: true, fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                          ),
                          style: const TextStyle(fontSize: 13),
                        )),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFEF4444), size: 18),
                          onPressed: () => setState(() => _pkgRows.removeAt(i)),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ] else ...[
                        const Text('Base:   ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                        Expanded(child: TextField(
                          controller: _pkgRows[i].nameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Tablet, Bottle',
                            isDense: true, filled: true, fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                          ),
                          style: const TextStyle(fontSize: 13),
                        )),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _pkgRows.insert(0, _PackagingRow('', '10'))),
                    child: const Row(
                      children: [
                        Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF4F46E5)),
                        SizedBox(width: 6),
                        Text('Add Parent Unit', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 540,
        constraints: const BoxConstraints(maxHeight: 680),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.08), blurRadius: 40, offset: const Offset(0, 20)),
            BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(28, 24, 20, 24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.category_rounded, color: Color(0xFF4F46E5), size: 24),
                ),
                const SizedBox(width: 16),
                const Text('Manage Categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                  splashRadius: 24,
                ),
              ]),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search categories...',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                            isDense: true,
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      if (_categories.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                              SizedBox(width: 12),
                              Text('No categories yet. Add one below.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                            ],
                          ),
                        ),

                      ..._categories.where((c) => (c['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase())).map((cat) {
                        final pkgList = <ProductUnit>[];
                        try {
                          final decoded = jsonDecode(cat['packaging'] as String) as List;
                          for (final e in decoded) { pkgList.add(ProductUnit.fromMap(e as Map<String, dynamic>)); }
                        } catch (_) {}
                        final pkgText = pkgList.isEmpty ? 'No packaging' : pkgList.map((u) => u.name).join(' → ');
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(cat['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A))),
                              const SizedBox(height: 3),
                              Text(pkgText, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                            ])),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                              onPressed: () => _deleteCategory(cat),
                              tooltip: 'Delete',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                            ),
                          ]),
                        );
                      }),

                      const SizedBox(height: 8),
                      if (!_isAdding)
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _isAdding = true),
                          icon: const Icon(Icons.add_rounded, size: 20, color: Color(0xFF4F46E5)),
                          label: const Text('Add New Category', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 14)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE0E7FF), width: 1.5),
                            foregroundColor: const Color(0xFF4F46E5),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      else ...[
                        const Divider(color: Color(0xFFF1F5F9), height: 24),
                        const Text('New Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                        const SizedBox(height: 14),
                        const Text('Category Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569), letterSpacing: 0.2)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Injection, Cream',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                            isDense: true,
                            filled: true,
                            fillColor: Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF4F46E5), width: 2)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 18),
                        _buildPackagingEditor(),
                        const SizedBox(height: 20),
                        Row(children: [
                          OutlinedButton(
                            onPressed: () => setState(() => _isAdding = false),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _addCategory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: const Text('Save Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ),
                        ]),
                      ],
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

