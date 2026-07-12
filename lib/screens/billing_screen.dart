import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/daily_sales_sheet.dart';
import '../models/sale.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';
import '../utils/app_feedback.dart';
import '../widgets/executive_header.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ─────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  static const Color _primary = Color(0xFF0F4C81);
  static const Color _pageBg = Color(0xFFF5F7FA);

  final TextEditingController _searchController = TextEditingController();
  List<Sale> _sales = [];
  DailySalesSheet? _currentDSS;
  bool _isLoading = true;

  // ── Summary Stats ─────────────────────────
  double get _netSalesBooked => _sales.fold(0, (s, i) => s + i.total);
  int get _invoiceCount => _sales.length;
  double get _cashCollected => _sales.fold(0, (s, i) => s + i.received);
  int get _fullySettled => _sales.where((i) => i.balance == 0).length;
  double get _outstandingBalance => _sales.fold(0, (s, i) => s + i.balance);
  int get _partialCount => _sales.where((i) => i.balance > 0).length;


  @override
  void initState() {
    super.initState();
    _loadData();
  }


  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final dss = await DatabaseHelper.instance.getCurrentOpenDSS();
    if (dss != null) {
      final sales = await DatabaseHelper.instance.getSalesForDSS(dss.id!);
      setState(() {
        _currentDSS = dss;
        _sales = sales;
        _isLoading = false;
      });
    } else {
      setState(() {
        _currentDSS = null;
        _sales = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showNewSaleDialog() {
    if (_currentDSS == null) return;
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (_) =>
          _NewSaleDialog(dssId: _currentDSS!.id!, onSaleAdded: _loadData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const ExecutiveHeader(
                    title: 'Sales',
                    subtitle: 'Manage daily invoices, track collections, and monitor outstanding balances.',
                  ),
                  const SizedBox(height: 20),
                  
                  _buildSummaryCards(),
                  const SizedBox(height: 20),
                  _buildActionBar(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 0),
                  _buildInvoiceTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  

  // ── Summary Cards ─────────────────────────
  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.receipt_long_outlined,
            iconColor: _primary,
            iconBg: const Color(0xFFEBF3FB),
            label: 'Net sales booked',
            value:
                'Rs. ${_netSalesBooked == 0 ? '0' : _netSalesBooked.toStringAsFixed(0)}',
            subLabel:
                '$_invoiceCount invoice${_invoiceCount == 1 ? '' : 's'} recorded',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            icon: Icons.payments_outlined,
            iconColor: const Color(0xFF16A34A),
            iconBg: const Color(0xFFE6F9F0),
            label: 'Cash collected',
            value:
                'Rs. ${_cashCollected == 0 ? '0' : _cashCollected.toStringAsFixed(0)}',
            subLabel: '$_fullySettled fully settled',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
            label: 'Outstanding balance',
            value:
                'Rs. ${_outstandingBalance == 0 ? '0' : _outstandingBalance.toStringAsFixed(0)}',
            subLabel: _partialCount == 0
                ? 'No partial invoices'
                : '$_partialCount partial invoice${_partialCount == 1 ? '' : 's'}',
          ),
        ),
      ],
    );
  }

  // ── Action Bar ────────────────────────────
  Widget _buildActionBar() {
    return Row(
      children: [
        // Filter badges
        _FilterBadge(
          label: '$_invoiceCount invoice${_invoiceCount == 1 ? '' : 's'}',
          icon: Icons.receipt_outlined,
          color: Colors.grey.shade700,
          bg: Colors.grey.shade100,
        ),
        const SizedBox(width: 8),
        _FilterBadge(
          label: _currentDSS == null ? 'DSS Closed' : 'DSS Open',
          icon: Icons.description_outlined,
          color: _currentDSS == null ? Colors.red : const Color(0xFF0F4C81),
          bg: _currentDSS == null
              ? Colors.red.shade50
              : const Color(0xFFEBF3FB),
        ),
        const Spacer(),
        // Action buttons
        _ActionButton(
          label: 'Export PDF',
          icon: Icons.picture_as_pdf_outlined,
          onTap: () {},
        ),
        const SizedBox(width: 10),
        if (_currentDSS == null) ...[
          // Open DSS CTA
          ElevatedButton.icon(
            onPressed: _showOpenDSSDialog,
            icon: const Icon(Icons.lock_open, size: 18),
            label: const Text(
              'Open Daily Sales Sheet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ] else ...[
          // Close DSS
          _ActionButton(
            label: 'Close Day',
            icon: Icons.lock_outline,
            onTap: _showCloseDSSDialog,
          ),
          const SizedBox(width: 10),
          // New Sale CTA
          ElevatedButton.icon(
            onPressed: _showNewSaleDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'New Sale',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ],
    );
  }


  void _showOpenDSSDialog() {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 420,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A3356), Color(0xFF0F4C81), Color(0xFF1565C0)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                      ),
                      child: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 16),
                    const Text('Open Sales Shift',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    Text('Start accepting sales for today',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFD9F5)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFF0F4C81), size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Opening a new Daily Sales Sheet will allow you to record sales for today.',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor: Colors.grey.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF0F4C81), Color(0xFF1565C0)]),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF0F4C81).withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                try {
                                  await DatabaseHelper.instance.openDSS(0);
                                  _loadData();
                                } catch (e) {
                                  if (mounted) {
                                    AppFeedback.show(context, e.toString(), type: AppFeedbackType.error);
                                  }
                                }
                              },
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                              label: const Text('Open Shift', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCloseDSSDialog() {
    if (_currentDSS == null) return;
    final dssId = _currentDSS!.id!;
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 420,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.red.shade900, Colors.red.shade700, Colors.red.shade500],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                      ),
                      child: const Icon(Icons.lock_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 16),
                    const Text('Close Sales Shift',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    Text('End the current Daily Sales Sheet',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Closing the sales sheet will lock today's records. No new sales can be added until a new shift is opened.",
                              style: TextStyle(fontSize: 13, color: Colors.red.shade800, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor: Colors.grey.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.red.shade700, Colors.red.shade500]),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.red.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                try {
                                  final closingDss = _currentDSS!;
                                  final closingSales = List<Sale>.from(_sales);
                                  await DatabaseHelper.instance.closeDSS(dssId, 0);
                                  _loadData();
                                  if (mounted) {
                                    showDialog(
                                      context: context,
                                      useRootNavigator: true,
                                      barrierColor: Colors.black.withOpacity(0.45),
                                      builder: (ctx) => _DSSClosedReportDialog(
                                        dss: closingDss,
                                        sales: closingSales,
                                        actualCash: 0,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    AppFeedback.show(context, e.toString(), type: AppFeedbackType.error);
                                  }
                                }
                              },
                              icon: const Icon(Icons.lock_rounded, size: 18),
                              label: const Text('Close Day', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // ── Search Bar ────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by invoice number',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Invoice Table ─────────────────────────
  Widget _buildInvoiceTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border(
          left: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                _th('INVOICE', flex: 3),
                _th('DATE', flex: 3),
                _th('CUSTOMER', flex: 4),
                _th('TOTAL', flex: 2),
                _th('RECEIVED', flex: 2),
                _th('BALANCE', flex: 2),
                _th('METHOD', flex: 2),
                _th('STATUS', flex: 2),
                _th('ACTIONS', flex: 2, alignRight: true),
              ],
            ),
          ),
          // Table body
          _isLoading
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              : (_sales.isEmpty || _currentDSS == null)
              ? _buildEmptyState()
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sales.length,
                  separatorBuilder: (_, index) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (_, i) => _SaleRow(sale: _sales[i]),
                ),
        ],
      ),
    );
  }

  Widget _th(String text, {required int flex, bool alignRight = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade400,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String subLabel;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A2E2B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subLabel,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;

  const _FilterBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _hovering ? Colors.grey.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _hovering ? Colors.grey.shade300 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaleRow extends StatefulWidget {
  final Sale sale;

  const _SaleRow({required this.sale});

  @override
  State<_SaleRow> createState() => _SaleRowState();
}

class _SaleRowState extends State<_SaleRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = DateTime.parse(widget.sale.date);
    final dateStr = '${d.day} ${months[d.month - 1]} ${d.year}';

    Color statusColor;
    Color statusBg;
    switch (widget.sale.status.toLowerCase()) {
      case 'paid':
        statusColor = const Color(0xFF16A34A);
        statusBg = const Color(0xFFE6F9F0);
        break;
      case 'partial':
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
        break;
      default:
        statusColor = Colors.grey.shade600;
        statusBg = Colors.grey.shade100;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hovering ? const Color(0xFFF5F7FA) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                widget.sale.invoiceNumber,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F4C81),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                dateStr,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                widget.sale.customerName ?? 'Walk-in',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2E2B),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Rs. ${widget.sale.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Rs. ${widget.sale.received.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Rs. ${widget.sale.balance.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 13,
                  color: widget.sale.balance > 0
                      ? const Color(0xFFD97706)
                      : Colors.grey.shade600,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                widget.sale.paymentMethod,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.sale.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: _hovering ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RowIconBtn(
                        icon: Icons.visibility_outlined,
                        tooltip: 'View',
                        onTap: () => _showSaleViewDialog(context),
                      ),
                      const SizedBox(width: 4),
                      _RowIconBtn(
                        icon: Icons.print_outlined,
                        tooltip: 'Print',
                        onTap: () => _printReceipt(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSaleViewDialog(BuildContext context) async {
    final items = await DatabaseHelper.instance.getSaleItems(widget.sale.id!);
    if (!context.mounted) return;

    final d = DateTime.parse(widget.sale.date);
    final dateStr = '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    
    Color statusColor;
    Color statusBg;
    switch (widget.sale.status.toLowerCase()) {
      case 'paid':
        statusColor = const Color(0xFF16A34A);
        statusBg = const Color(0xFFE6F9F0);
        break;
      case 'partial':
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
        break;
      default:
        statusColor = Colors.grey.shade600;
        statusBg = Colors.grey.shade100;
    }
    
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 550,
            constraints: const BoxConstraints(maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Invoice Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.sale.invoiceNumber,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.close, color: Colors.grey.shade600, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      )
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Metadata Grid
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildMetaItem('Date', dateStr),
                              ),
                              Expanded(
                                child: _buildMetaItem('Customer', widget.sale.customerName ?? 'Walk-in'),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Status',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        widget.sale.status,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Items Header
                        const Text(
                          'Purchased Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text('ITEM', style: _tableHeaderStyle())),
                              Expanded(flex: 1, child: Text('QTY', style: _tableHeaderStyle(), textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text('PRICE', style: _tableHeaderStyle(), textAlign: TextAlign.right)),
                              Expanded(flex: 2, child: Text('TOTAL', style: _tableHeaderStyle(), textAlign: TextAlign.right)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Items List
                        ...items.map((item) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    item.productName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151)),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    '${item.quantity}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey.shade600),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Rs. ${item.price.toStringAsFixed(0)}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey.shade600),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Rs. ${(item.price * item.quantity).toStringAsFixed(0)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF111827)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        
                        const SizedBox(height: 24),
                        
                        // Summary Section
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 250,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                _buildSummaryRow('Total Amount', widget.sale.total, isBold: true),
                                const SizedBox(height: 12),
                                _buildSummaryRow('Received', widget.sale.received, color: const Color(0xFF16A34A)),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(height: 1),
                                ),
                                _buildSummaryRow(
                                  'Balance Due', 
                                  widget.sale.balance, 
                                  isBold: true,
                                  color: widget.sale.balance > 0 ? const Color(0xFFDC2626) : const Color(0xFF111827),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          foregroundColor: Colors.grey.shade700,
                        ),
                        child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _printReceipt(context);
                        },
                        icon: const Icon(Icons.print_outlined, size: 18),
                        label: const Text('Print Receipt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F4C81),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  TextStyle _tableHeaderStyle() {
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Colors.grey.shade500,
      letterSpacing: 0.5,
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false, Color? color, double size = 14}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: size - 1,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: isBold ? const Color(0xFF111827) : Colors.grey.shade600,
          ),
        ),
        Text(
          'Rs. ${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: size,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color ?? (isBold ? const Color(0xFF111827) : Colors.grey.shade700),
          ),
        ),
      ],
    );
  }

  Future<void> _printReceipt(BuildContext context) async {
    final items = await DatabaseHelper.instance.getSaleItems(widget.sale.id!);
    final settingsData = await DatabaseHelper.instance.getAllSettings();
    final shopName = settingsData['shop_name']?.isNotEmpty == true ? settingsData['shop_name']! : 'PHARMACY RECEIPT';
    final phone = settingsData['shop_phone'] ?? '';
    final address = settingsData['shop_address'] ?? '';
    final showTax = (settingsData['show_tax_in_receipt'] ?? 'true') == 'true';
    
    // Process items for parent unit display
    final processedItems = <Map<String, dynamic>>[];
    for (var item in items) {
      final product = await DatabaseHelper.instance.getProduct(item.productId);
      int multiplier = 1;
      if (product != null) {
        final match = RegExp(r'\((.*?)\)$').firstMatch(item.productName);
        if (match != null) {
          final unitName = match.group(1)!;
          multiplier = product.getMultiplier(unitName);
        }
      }
      if (multiplier < 1) multiplier = 1;
      
      final displayQty = item.quantity / multiplier;
      final displayPrice = item.price * multiplier;
      final displayAmount = displayPrice * displayQty;
      
      processedItems.add({
        'name': item.productName,
        'qty': displayQty.toInt().toString(),
        'price': displayPrice,
        'amount': displayAmount,
      });
    }
    
    // Parse date and time if possible
    pw.Widget divider() {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Text(
          '------------------------------------------------------------------',
          maxLines: 1,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
      );
    }
    String dateStr = widget.sale.date;
    String timeStr = '';
    try {
      final dt = DateTime.parse(widget.sale.date);
      dateStr = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      timeStr = "${dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour)}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}";
    } catch (e) {
      // Fallback if not parseable
      final parts = widget.sale.date.split(' ');
      if (parts.length > 1) {
        dateStr = parts[0];
        timeStr = parts[1];
      }
    }
    
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(68 * PdfPageFormat.mm, double.infinity, marginAll: 2 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(shopName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14), textAlign: pw.TextAlign.center),
              if (address.isNotEmpty) pw.Text(address, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
              if (phone.isNotEmpty) pw.Text('Contact: $phone', style: const pw.TextStyle(fontSize: 8)),
              divider(),
              pw.Text('INVOICE INFORMATION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              divider(),
              
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Inv #: ${widget.sale.invoiceNumber}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('Time: $timeStr', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Cust: ${widget.sale.customerName ?? 'Walk-in'}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('Status: ${widget.sale.balance <= 0 ? 'PAID' : 'PENDING'}', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                ],
              ),
              
              divider(),
              pw.Text('PRODUCT DETAILS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              divider(),
              
              pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('Item', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 1, child: pw.Text('Qty', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  pw.Expanded(flex: 2, child: pw.Text('Price', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  pw.Expanded(flex: 2, child: pw.Text('Amount', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                ],
              ),
              divider(),
              
              ...processedItems.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text(item['name'], style: const pw.TextStyle(fontSize: 8))),
                      pw.Expanded(flex: 1, child: pw.Text(item['qty'], style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                      pw.Expanded(flex: 2, child: pw.Text((item['price'] as double).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                      pw.Expanded(flex: 2, child: pw.Text((item['amount'] as double).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                );
              }),
              
              divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text((widget.sale.total + widget.sale.discount - (showTax ? widget.sale.taxAmount : 0)).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              if (showTax && widget.sale.taxAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tax (${widget.sale.taxRate}%)', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(widget.sale.taxAmount.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              if (widget.sale.discount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('-${widget.sale.discount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GRAND TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(widget.sale.total.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ],
              ),
              divider(),
              
              pw.Container(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 2),
                    pw.Text('NOTES:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text('1. Products cannot be returned without a receipt.', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('2. No returns accepted after 7 days.', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('3. Please check your receipt and cash before leaving.', style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 2),
                  ]
                ),
              ),
              divider(),
              
              pw.Text('Powered By TryUnity Solutions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text('Contact: +92 302 3476605', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Email: dev-alee@outlook.com', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 4),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}

class _RowIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RowIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: Colors.grey.shade600),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NEW SALE DIALOG
// ─────────────────────────────────────────────

class _NewSaleDialog extends StatefulWidget {
  final int dssId;
  final VoidCallback onSaleAdded;

  const _NewSaleDialog({required this.dssId, required this.onSaleAdded});

  @override
  State<_NewSaleDialog> createState() => _NewSaleDialogState();
}

class _NewSaleDialogState extends State<_NewSaleDialog> {
  static const Color _primary = Color(0xFF0F4C81);

  final List<_CartItem> _cart = [];
  Customer? _selectedCustomer;
  String _paymentMethod = 'Cash';

  List<Customer> _customers = [];
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isSaving = false;

  // Staging: product selected from autocomplete, awaiting unit+qty confirmation
  Product? _stagedProduct;
  String? _stagedUnit;
  int _stagedQty = 1;

  final TextEditingController _receivedController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _discountController = TextEditingController(text: '0');
  String _discountType = 'Rupees';
  String? _validationError;
  String? _stagedError;
  double _taxRate = 0.0;

  double get _subtotal => _cart.fold(0, (s, i) => s + i.total);
  double get _discountAmount {
    final val = double.tryParse(_discountController.text) ?? 0.0;
    if (_discountType == 'Percentage') {
      return _subtotal * (val / 100);
    }
    return val;
  }
  double get _taxAmount => (_subtotal - _discountAmount) * (_taxRate / 100);
  double get _total => (_subtotal - _discountAmount + _taxAmount).roundToDouble();
  double get _stagedPricePerUnit {
    if (_stagedProduct == null || _stagedUnit == null) return 0;
    final p = _stagedProduct!;
    if (p.packaging.isEmpty) return p.sellPrice;
    // sellPrice is entered per the FIRST (largest) unit (e.g. Box)
    // scale proportionally: pricePerSelectedUnit = sellPrice * multiplier(selectedUnit) / multiplier(firstUnit)
    final firstMultiplier = p.getMultiplier(p.packaging.first.name);
    return p.sellPrice * p.getMultiplier(_stagedUnit!) / firstMultiplier;
  }

  double get _stagedLineTotal => _stagedPricePerUnit * _stagedQty;


  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper.instance.getAllSettings();
    if (mounted) {
      setState(() {
        _paymentMethod = settings['default_payment_method'] ?? 'Cash';
        _taxRate = double.tryParse(settings['tax_rate'] ?? '0') ?? 0.0;
      });
    }
  }


  @override
  void dispose() {
    _receivedController.dispose();
    _qtyController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final customers = await DatabaseHelper.instance.getCustomers();
    final products = await DatabaseHelper.instance.getAllProducts();
    if (mounted) {
      setState(() {
        _customers = customers.where((c) => c.id != 'walk-in-customer').toList();
        _products = products;
        _isLoading = false;
      });
    }
  }

  void _stageProduct(Product p) {
    setState(() {
      _stagedProduct = p;
      _stagedUnit = p.packaging.isNotEmpty ? p.packaging.first.name : null;
      _stagedQty = 1;
      _qtyController.text = '1';
    });
  }

  void _addStagedToCart() {
    if (_stagedProduct == null) return;
    final p = _stagedProduct!;
    final unit =
        _stagedUnit ??
        (p.packaging.isNotEmpty ? p.packaging.first.name : 'Unit');
    // Price per the selected unit, proportional to the first (largest) unit price
    final firstMultiplier = p.packaging.isNotEmpty
        ? p.getMultiplier(p.packaging.first.name)
        : 1;
    final pricePerUnit = p.packaging.isEmpty
        ? p.sellPrice
        : p.sellPrice * p.getMultiplier(unit) / firstMultiplier;

    final requestedBaseUnits = _stagedQty * p.getMultiplier(unit);
    final currentCartBaseUnits = _cart
        .where((c) => c.product.id == p.id)
        .fold(0, (sum, c) => sum + c.baseUnits);

    if (currentCartBaseUnits + requestedBaseUnits > p.stock) {
      setState(() {
        _stagedError = 'Not enough stock! Available: ${p.formattedStock}';
      });
      return;
    }

    setState(() {
      _stagedError = null;
      final existingIndex = _cart.indexWhere((c) => c.product.id == p.id);
      
      if (existingIndex >= 0) {
        if (_cart[existingIndex].unit == unit) {
          _cart[existingIndex].unitQty += _stagedQty;
        } else {
          _stagedError = 'Product already in invoice. Please edit the existing item.';
          return;
        }
      } else {
        _cart.add(
          _CartItem(
            product: p,
            unit: unit,
            unitQty: _stagedQty,
            pricePerUnit: pricePerUnit,
          ),
        );
      }
      _stagedProduct = null;
      _stagedUnit = null;
      _stagedQty = 1;
      _qtyController.text = '1';
      _stagedError = null;
    });
  }

  List<String> _unitOptionsForProduct(Product product) {
    if (product.packaging.isEmpty) return ['Base Unit'];
    return product.packaging.map((u) => u.name).toList();
  }

  double _pricePerUnitFor(Product product, String unit) {
    if (product.packaging.isEmpty) return product.sellPrice;
    final firstMultiplier = product.getMultiplier(product.packaging.first.name);
    return product.sellPrice * product.getMultiplier(unit) / firstMultiplier;
  }

  Future<void> _editCartItem(int index) async {
    final item = _cart[index];
    final qtyController = TextEditingController(text: item.unitQty.toString());
    String selectedUnit = item.unit;
    final units = _unitOptionsForProduct(item.product);

    final edited = await showDialog<_CartItem>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final otherBaseUnits = _cart
                .asMap()
                .entries
                .where((entry) => entry.key != index && entry.value.product.id == item.product.id)
                .fold(0, (sum, entry) => sum + entry.value.baseUnits);
            final multiplier = item.product.getMultiplier(selectedUnit);
            final maxQty = ((item.product.stock - otherBaseUnits) / multiplier).floor().clamp(0, item.product.stock.toInt());
            final pricePerUnit = _pricePerUnitFor(item.product, selectedUnit);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Edit cart item'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedUnit,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setDialogState(() {
                          selectedUnit = val;
                          final newMultiplier = item.product.getMultiplier(selectedUnit);
                          final newMaxQty = ((item.product.stock - otherBaseUnits) / newMultiplier).floor();
                          final currentQty = int.tryParse(qtyController.text.trim()) ?? 1;
                          if (currentQty > newMaxQty) {
                            qtyController.text = newMaxQty.clamp(0, 999999).toString();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        helperText: 'Max: $maxQty',
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Price: Rs. ${pricePerUnit.toStringAsFixed(0)} / $selectedUnit',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final qty = int.tryParse(qtyController.text.trim()) ?? 0;
                    if (qty <= 0 || qty > maxQty) {
                      AppFeedback.show(
                        context,
                        'Enter a valid quantity within stock limits.',
                        type: AppFeedbackType.warning,
                      );
                      return;
                    }
                    Navigator.pop(
                      dialogContext,
                      _CartItem(
                        product: item.product,
                        unit: selectedUnit,
                        unitQty: qty,
                        pricePerUnit: pricePerUnit,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C81),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    qtyController.dispose();

    if (edited != null && mounted) {
      setState(() => _cart[index] = edited);
    }
  }

  void _saveSale() async {
    if (_cart.isEmpty) return;

    double received = double.tryParse(_receivedController.text) ?? 0.0;
    if (_paymentMethod == 'Cash' &&
        received < _total &&
        _selectedCustomer == null) {
      setState(() {
        _validationError = 'Cannot have pending balance for walk-in customer';
      });
      return;
    }

    setState(() {
      _validationError = null;
    });

    if (_paymentMethod != 'Cash') {
      received = _total;
    }

    final balance = _total - received;
    setState(() => _isSaving = true);

    try {
      final invoiceNumber = await DatabaseHelper.instance.nextSaleInvoiceNumber();
      final sale = Sale(
        invoiceNumber: invoiceNumber,
        dssId: widget.dssId,
        customerId: _selectedCustomer?.id ?? 'walk-in-customer',
        customerName: _selectedCustomer?.name ?? 'Walk-in Customer',
        date: DateTime.now().toIso8601String(),
        total: _total,
        received: received,
        balance: balance,
        paymentMethod: _paymentMethod,
        status: balance > 0 ? 'Partial' : 'Paid',
          taxRate: _taxRate,
          taxAmount: _taxAmount,
          discount: _discountAmount,
          createdByUserId: AuthService.instance.currentUserId,
          createdByRole: AuthService.instance.currentUserRole,
        );

      final items = _cart
          .map(
            (c) => SaleItem(
              productId: c.product.id!,
              productName: '${c.product.name} (${c.unit})',
              quantity: c.baseUnits,
              price: c.total / c.baseUnits,
              total: c.total,
            ),
          )
          .toList();

      await DatabaseHelper.instance.insertSale(sale, items);

      if (mounted) {
        widget.onSaleAdded();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.show(context, e.toString(), type: AppFeedbackType.error);
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(
        child: SizedBox(
          width: 700,
          height: 580,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 800,
        height: 650,
        child: Column(
          children: [
            // Dialog header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  const Text(
                    'New Sale',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A2E2B),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.grey.shade500,
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Customer + Payment Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<Customer?>(
                            decoration: InputDecoration(
                              labelText: 'Customer',
                              hintText: 'Walk-in Customer',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                size: 17,
                                color: Colors.grey.shade400,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            value: _selectedCustomer,
                            hint: const Text('Walk-in Customer'),
                            items: [
                              ..._customers.map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.name),
                                ),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() {
                                  _selectedCustomer = val;
                                  _validationError = null;
                                }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Payment Method',
                              prefixIcon: Icon(
                                Icons.payment_outlined,
                                size: 17,
                                color: Colors.grey.shade400,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            value: _paymentMethod,
                            items: ['Cash', 'Card', 'Bank Transfer', 'Other']
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _paymentMethod = val!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _receivedController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() => _validationError = null),
                            decoration: InputDecoration(
                              labelText: 'Amount Received (Rs)',
                              errorText: _validationError,
                              errorMaxLines: 2,
                              prefixIcon: Icon(
                                Icons.money,
                                size: 17,
                                color: Colors.grey.shade400,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Discount Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Discount Type',
                              prefixIcon: Icon(
                                Icons.local_offer_outlined,
                                size: 17,
                                color: Colors.grey.shade400,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide.none),
                            ),
                            value: _discountType,
                            items: ['Rupees', 'Percentage'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                            onChanged: (val) => setState(() => _discountType = val!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _discountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Discount Value',
                              prefixIcon: Icon(
                                _discountType == 'Percentage' ? Icons.percent : Icons.money,
                                size: 17,
                                color: Colors.grey.shade400,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide.none),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Medicine search (Autocomplete)
                    Autocomplete<Product>(
                      displayStringForOption: (option) => option.name,
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty)
                          return const Iterable<Product>.empty();
                        return _products.where(
                          (p) => p.name.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          ),
                        );
                      },
                      onSelected: (Product selection) =>
                          _stageProduct(selection),
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: 'Add Medicine',
                                hintText: 'Search by name...',
                                prefixIcon: Icon(
                                  Icons.medication_outlined,
                                  size: 17,
                                  color: Colors.grey.shade400,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(9),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            );
                          },
                    ),
                    // Staging area: unit + qty picker
                    if (_stagedProduct != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _stagedProduct!.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Color(0xFF0F4C81),
                                    ),
                                  ),
                                  Text(
                                    'Stock: ${_stagedProduct!.formattedStock}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Unit dropdown
                            if (_stagedProduct!.packaging.isNotEmpty)
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: _stagedUnit,
                                  isDense: true,
                                  decoration: InputDecoration(
                                    labelText: 'Unit',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  items: _stagedProduct!.packaging
                                      .map(
                                        (u) => DropdownMenuItem(
                                          value: u.name,
                                          child: Text(u.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => _stagedUnit = val),
                                ),
                              ),
                            const SizedBox(width: 10),
                            // Qty field
                            SizedBox(
                              width: 75,
                              child: TextFormField(
                                controller: _qtyController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  labelText: 'Qty',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (val) => setState(
                                  () => _stagedQty = int.tryParse(val) ?? 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Price preview
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Rs. ${_stagedPricePerUnit.toStringAsFixed(0)}/unit',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '= Rs. ${_stagedLineTotal.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: _primary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: _addStagedToCart,
                              icon: const Icon(
                                Icons.add_shopping_cart,
                                size: 15,
                              ),
                              label: const Text('Add'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.grey.shade500,
                              ),
                              onPressed: () =>
                                  setState(() => _stagedProduct = null),
                              tooltip: 'Cancel',
                            ),
                              ],
                            ),
                            if (_stagedError != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _stagedError!,
                                      style: const TextStyle(color: Colors.red, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Cart
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _cart.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 40,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'No items added yet',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  // Cart header
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(10),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Expanded(
                                          flex: 4,
                                          child: Text(
                                            'PRODUCT',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const Expanded(
                                          flex: 2,
                                          child: Text(
                                            'UNIT',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const Expanded(
                                          flex: 1,
                                          child: Text(
                                            'QTY',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey,
                                              letterSpacing: 0.5,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const Expanded(
                                          flex: 2,
                                          child: Text(
                                            'PRICE/UNIT',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey,
                                              letterSpacing: 0.5,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                        const Expanded(
                                          flex: 2,
                                          child: Text(
                                            'TOTAL',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey,
                                              letterSpacing: 0.5,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                        const SizedBox(width: 40),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.separated(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      itemCount: _cart.length,
                                      separatorBuilder: (_, index) => Divider(
                                        height: 1,
                                        color: Colors.grey.shade100,
                                      ),
                                      itemBuilder: (_, i) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 4,
                                              child: Text(
                                                _cart[i].product.name,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFEFF6FF,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  _cart[i].unit,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF0F4C81),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () => setState(() {
                                                      if (_cart[i].unitQty >
                                                          1) {
                                                        _cart[i].unitQty--;
                                                      } else {
                                                        _cart.removeAt(i);
                                                      }
                                                    }),
                                                    child: Icon(
                                                      Icons
                                                          .remove_circle_outline,
                                                      size: 16,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${_cart[i].unitQty}',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  GestureDetector(
                                                    onTap: () {
                                                      final item = _cart[i];
                                                      final p = item.product;
                                                      final currentBaseUnits = _cart
                                                          .where((c) => c.product.id == p.id)
                                                          .fold(0, (sum, c) => sum + c.baseUnits);
                                                      final extraBaseUnits = p.getMultiplier(item.unit);
                                                      
                                                      if (currentBaseUnits + extraBaseUnits > p.stock) {
                                                        AppFeedback.show(context, 'Not enough stock! Available: ${p.formattedStock}', type: AppFeedbackType.error);
                                                        return;
                                                      }
                                                      
                                                      setState(
                                                        () => _cart[i].unitQty++,
                                                      );
                                                    },
                                                    child: Icon(
                                                      Icons.add_circle_outline,
                                                      size: 16,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Rs. ${_cart[i].pricePerUnit.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade600,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Rs. ${_cart[i].total.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: _primary,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 40,
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 16,
                                                  color: _primary,
                                                ),
                                                onPressed: () => _editCartItem(i),
                                                tooltip: 'Edit',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Subtotal: ', style: TextStyle(color: Colors.grey.shade600)),
                          Text('Rs. ${_subtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Discount: ', style: TextStyle(color: Colors.grey.shade600)),
                          Text('- Rs. ${_discountAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                        ],
                      ),
                      if (_taxAmount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Tax (${_taxRate.toStringAsFixed(1)}%): ', style: TextStyle(color: Colors.grey.shade600)),
                            Text('+ Rs. ${_taxAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.orange)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Total: ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          Text(
                            'Rs. ${_total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _cart.isEmpty || _isSaving ? null : _saveSale,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save & Print',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
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

class _CartItem {
  final Product product;
  final String unit; // selected unit name (e.g. 'Box', 'Strip', 'Tablet')
  int unitQty; // quantity in the selected unit
  final double pricePerUnit; // price per selected unit

  _CartItem({
    required this.product,
    required this.unit,
    required this.unitQty,
    required this.pricePerUnit,
  });

  double get total => pricePerUnit * unitQty;

  /// Base units to deduct from stock
  int get baseUnits => unitQty * product.getMultiplier(unit);
}

class _OpenDSSDialog extends StatefulWidget {
  final VoidCallback onOpened;

  const _OpenDSSDialog({required this.onOpened});

  @override
  State<_OpenDSSDialog> createState() => _OpenDSSDialogState();
}

class _OpenDSSDialogState extends State<_OpenDSSDialog> {
  final TextEditingController _balanceController = TextEditingController();
  bool _isSaving = false;

  void _save() async {
    final balance = double.tryParse(_balanceController.text) ?? 0.0;
    setState(() => _isSaving = true);
    try {
      await DatabaseHelper.instance.openDSS(balance);
      if (mounted) {
        widget.onOpened();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.show(context, e.toString(), type: AppFeedbackType.error);
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Open Daily Sales Sheet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F4C81),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter the opening cash balance in the till to start the day.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Opening Cash Balance (Rs)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C81),
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Open Shift'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DSSClosedReportDialog extends StatefulWidget {
  final DailySalesSheet dss;
  final List<Sale> sales;
  final double actualCash;

  const _DSSClosedReportDialog({
    required this.dss,
    required this.sales,
    required this.actualCash,
  });

  @override
  State<_DSSClosedReportDialog> createState() => _DSSClosedReportDialogState();
}

class _DSSClosedReportDialogState extends State<_DSSClosedReportDialog> {
  int _qtySold = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    int qty = 0;
    for (var s in widget.sales) {
      if (s.status != 'Returned') {
        final items = await DatabaseHelper.instance.getSaleItems(s.id!);
        qty += items.fold(0, (sum, i) => sum + i.quantity);
      }
    }
    if (mounted) {
      setState(() {
        _qtySold = qty;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int invoicesCount = widget.sales.where((s) => s.status != 'Returned').length;
    int returnsCount = widget.sales.where((s) => s.status == 'Returned').length;
    double salesValue = widget.sales.where((s) => s.status != 'Returned').fold(0.0, (s, i) => s + i.total);
    double returnValue = widget.sales.where((s) => s.status == 'Returned').fold(0.0, (s, i) => s + i.total);
    double netSales = salesValue - returnValue;

    final currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final dssName = 'DSS-${widget.dss.id}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bar_chart, color: Color(0xFF5A67D8), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DSS Close Report',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dssName closed successfully. Here is the end-of-day summary.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey.shade400, size: 20),
                )
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD1FAE5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF059669), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cash in hand after close', style: TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
                        const SizedBox(height: 4),
                        Text(currency.format(widget.actualCash), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                        const SizedBox(height: 4),
                        Text('$dssName closed on $dateStr', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Daily Sales Sheet Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A202C))),
                  const SizedBox(height: 4),
                  Text('A quick end-of-day snapshot of invoices, returns, quantities, and cash movement for this sheet.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildGridItem(Icons.receipt_long_outlined, const Color(0xFF5A67D8), 'Invoices in DSS', invoicesCount.toString())),
                      const SizedBox(width: 16),
                      Expanded(child: _buildGridItem(Icons.assignment_return_outlined, const Color(0xFFD97706), 'Returns in DSS', returnsCount.toString(), isOrange: true)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildGridItem(Icons.trending_up, const Color(0xFF2563EB), 'Sales value', currency.format(salesValue))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildGridItem(Icons.undo, const Color(0xFFDC2626), 'Return value', currency.format(returnValue), isRed: true)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildGridItem(Icons.inventory_2_outlined, const Color(0xFF5A67D8), 'Qty sold', _loading ? '...' : _qtySold.toString())),
                      const SizedBox(width: 16),
                      Expanded(child: _buildGridItem(Icons.show_chart, const Color(0xFF059669), 'Net sales', currency.format(netSales), isGreen: true)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A67D8),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildGridItem(IconData icon, Color color, String title, String value, {bool isOrange = false, bool isRed = false, bool isGreen = false}) {
    Color bgColor = const Color(0xFFF3F4F6);
    if (isOrange) bgColor = const Color(0xFFFFFBEB);
    if (isRed) bgColor = const Color(0xFFFEF2F2);
    if (isGreen) bgColor = const Color(0xFFECFDF5);
    if (!isOrange && !isRed && !isGreen) bgColor = const Color(0xFFF0F2FA);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor == const Color(0xFFF0F2FA) ? const Color(0xFFE0E7FF) : 
                                 isOrange ? const Color(0xFFFEF3C7) : 
                                 isRed ? const Color(0xFFFEE2E2) : 
                                 isGreen ? const Color(0xFFD1FAE5) : Colors.transparent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))
              ]
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              ],
            ),
          )
        ],
      ),
    );
  }
}


