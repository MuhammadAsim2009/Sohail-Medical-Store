import 'package:flutter/material.dart';
import '../widgets/executive_header.dart';

// ---------------------------------------------------------------------------
// THEME TOKENS
// ---------------------------------------------------------------------------
const _kPrimary = Color(0xFF0F4C81);
const _kBg = Color(0xFFF5F7FA);

// ---------------------------------------------------------------------------
// DATA MODEL
// ---------------------------------------------------------------------------
class SalesReturnRecord {
  final String id;
  final DateTime date;
  final String invoiceNumber;
  final String customerName;
  final String mode;
  final double total;
  final double cash;
  final double credit;
  final String status;

  const SalesReturnRecord({
    required this.id,
    required this.date,
    required this.invoiceNumber,
    required this.customerName,
    required this.mode,
    required this.total,
    required this.cash,
    required this.credit,
    required this.status,
  });
}

// ---------------------------------------------------------------------------
// DUMMY DATA
// ---------------------------------------------------------------------------
final _dummyReturns = <SalesReturnRecord>[
  // TODO: Replace with real Firestore stream from 'salesReturns' collection
];

// ---------------------------------------------------------------------------
// SALES RETURN SCREEN
// ---------------------------------------------------------------------------
class SalesReturnScreen extends StatefulWidget {
  const SalesReturnScreen({super.key});

  @override
  State<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends State<SalesReturnScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'All posted';
  bool _dssOpen = true;

  // DSS info
  final String _dssId = 'DSS-20260627-3';
  final DateTime _dssDate = DateTime.now();

  List<SalesReturnRecord> get _filtered {
    final q = _searchQuery.trim().toLowerCase();
    return _dummyReturns.where((r) {
      if (q.isNotEmpty) {
        return r.id.toLowerCase().contains(q) ||
            r.invoiceNumber.toLowerCase().contains(q) ||
            r.customerName.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  double get _postedReturnValue =>
      _dummyReturns.where((r) => r.status == 'Posted').fold(0, (s, r) => s + r.total);
  double get _cashRefunded =>
      _dummyReturns.fold(0, (s, r) => s + r.cash);
  double get _customerCredit =>
      _dummyReturns.fold(0, (s, r) => s + r.credit);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Executive Header ─────────────────────────────────────
                  const ExecutiveHeader(
                    title: 'Sales Return',
                    subtitle: 'Manage returned invoices, refund review, and stock reversal workflows from one\ndedicated surface.',
                  ),
                  const SizedBox(height: 28),

                  // ── DSS Banner ───────────────────────────────────────────
                  if (_dssOpen) _buildDSSBanner(),
                  if (_dssOpen) const SizedBox(height: 20),

                  // ── Stat Cards ───────────────────────────────────────────
                  _buildStatCards(),
                  const SizedBox(height: 20),

                  // ── Action Bar ───────────────────────────────────────────
                  _buildActionBar(),
                  const SizedBox(height: 16),

                  // ── Search ───────────────────────────────────────────────
                  _buildSearchBar(),
                  const SizedBox(height: 0),

                  // ── Table ────────────────────────────────────────────────
                  _buildTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── DSS Banner ─────────────────────────────────────────────────────────────
  Widget _buildDSSBanner() {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = '${_dssDate.day} ${months[_dssDate.month - 1]} ${_dssDate.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.event_available_rounded, color: Colors.green.shade600, size: 22),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Sales Sheet Open',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(_dssId, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    _dot(),
                    Text(dateStr, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    _dot(),
                    Text('0 posted', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    _dot(),
                    Text('0 drafts', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    _dot(),
                    Text('Rs. 0 value', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),

          // Close DSS button
          OutlinedButton.icon(
            onPressed: () => setState(() => _dssOpen = false),
            icon: Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade700),
            label: Text('Close DSS', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Text('◆', style: TextStyle(fontSize: 8, color: Colors.grey.shade400)),
  );

  // ── Stat Cards ─────────────────────────────────────────────────────────────
  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Posted return value',
            value: 'Rs. ${_postedReturnValue.toStringAsFixed(0)}',
            subtitle: '${_dummyReturns.where((r) => r.status == "Posted").length} posted returns',
            iconBg: const Color(0xFFFFF3E0),
            icon: Icons.assignment_return_rounded,
            iconColor: const Color(0xFFF57C00),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Cash refunded',
            value: 'Rs. ${_cashRefunded.toStringAsFixed(0)}',
            subtitle: 'No drafts waiting',
            iconBg: const Color(0xFFFFEBEE),
            icon: Icons.payments_rounded,
            iconColor: const Color(0xFFE53935),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Customer credit',
            value: 'Rs. ${_customerCredit.toStringAsFixed(0)}',
            subtitle: 'Exchange and balance returns retained',
            iconBg: const Color(0xFFE3F2FD),
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF1976D2),
          ),
        ),
      ],
    );
  }

  // ── Action Bar ─────────────────────────────────────────────────────────────
  Widget _buildActionBar() {
    return Row(
      children: [
        // Filter chips
        _FilterChip(
          label: '${_filtered.length} return records',
          icon: Icons.receipt_long_outlined,
          selected: false,
          onTap: () {},
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'All posted',
          icon: Icons.check_circle_outline,
          selected: _activeFilter == 'All posted',
          selectedColor: Colors.green,
          onTap: () => setState(() => _activeFilter = 'All posted'),
        ),
        const Spacer(),

        // New Return button
        ElevatedButton.icon(
          onPressed: () => _showNewReturnDialog(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Return', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                hintText: 'Search by return or invoice number',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Table ──────────────────────────────────────────────────────────────────
  Widget _buildTable() {
    final rows = _filtered;

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
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: const Row(
              children: [
                _ColHeader('RETURN', flex: 2),
                _ColHeader('DATE', flex: 2),
                _ColHeader('INVOICE', flex: 2),
                _ColHeader('CUSTOMER', flex: 3),
                _ColHeader('MODE', flex: 2),
                _ColHeader('TOTAL', flex: 2),
                _ColHeader('CASH', flex: 2),
                _ColHeader('CREDIT', flex: 2),
                _ColHeader('STATUS', flex: 2),
                _ColHeader('ACTIONS', flex: 2),
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
                    Icon(Icons.assignment_return_outlined, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No return records yet', style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('Click "+ New Return" to record your first return', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                  ],
                ),
              ),
            ),

          // Data rows
          ...rows.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
            final dateStr = '${r.date.day} ${months[r.date.month - 1]} ${r.date.year}';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: i.isEven ? Colors.white : Colors.grey.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  _Col(r.id, flex: 2, bold: true, color: _kPrimary),
                  _Col(dateStr, flex: 2),
                  _Col(r.invoiceNumber, flex: 2),
                  _Col(r.customerName, flex: 3),
                  _Col(r.mode, flex: 2),
                  _Col('Rs. ${r.total.toStringAsFixed(0)}', flex: 2),
                  _Col('Rs. ${r.cash.toStringAsFixed(0)}', flex: 2),
                  _Col('Rs. ${r.credit.toStringAsFixed(0)}', flex: 2),
                  Expanded(
                    flex: 2,
                    child: _StatusBadge(r.status),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.visibility_outlined, size: 18, color: Colors.grey.shade500),
                          onPressed: () {},
                          tooltip: 'View',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade300),
                          onPressed: () {},
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
          }),
        ],
      ),
    );
  }

  // ── New Return Dialog ───────────────────────────────────────────────────────
  void _showNewReturnDialog() {
    showDialog(
      context: context,
      builder: (_) => const _NewReturnDialog(),
    );
  }
}

// ---------------------------------------------------------------------------
// STAT CARD
// ---------------------------------------------------------------------------
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color iconBg;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.iconBg,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A2E2B), letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
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
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color? selectedColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? Colors.grey.shade700;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.4) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? color : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? color : Colors.grey.shade700,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TABLE HELPERS
// ---------------------------------------------------------------------------
class _ColHeader extends StatelessWidget {
  final String label;
  final int flex;
  const _ColHeader(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5),
      ),
    );
  }
}

class _Col extends StatelessWidget {
  final String text;
  final int flex;
  final bool bold;
  final Color? color;
  const _Col(this.text, {required this.flex, this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: color ?? const Color(0xFF1A2E2B),
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case 'Posted':
        bg = Colors.green.shade50; fg = Colors.green.shade700;
        break;
      case 'Draft':
        bg = Colors.orange.shade50; fg = Colors.orange.shade700;
        break;
      case 'Cancelled':
        bg = Colors.red.shade50; fg = Colors.red.shade700;
        break;
      default:
        bg = Colors.grey.shade100; fg = Colors.grey.shade600;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

// ---------------------------------------------------------------------------
// NEW RETURN DIALOG
// ---------------------------------------------------------------------------
class _NewReturnDialog extends StatefulWidget {
  const _NewReturnDialog();

  @override
  State<_NewReturnDialog> createState() => _NewReturnDialogState();
}

class _NewReturnDialogState extends State<_NewReturnDialog> {
  final _invoiceCtrl = TextEditingController();
  String _selectedMode = 'Cash Refund';
  String _selectedReason = 'Damaged / Expired';

  static const _modes = ['Cash Refund', 'Store Credit', 'Original Payment Method'];
  static const _reasons = ['Damaged / Expired', 'Wrong Medicine Dispensed', 'Customer Changed Mind', 'Other'];

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.assignment_return_outlined, color: Color(0xFF1976D2), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('New Return', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
                      Text('Enter the original invoice number to begin', style: TextStyle(fontSize: 13, color: Color(0xFF8F9BB3))),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: Colors.grey.shade400)),
              ],
            ),
            const SizedBox(height: 24),

            // Invoice number
            const Text('Invoice Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B))),
            const SizedBox(height: 8),
            TextField(
              controller: _invoiceCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. INV-1042',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.receipt_outlined, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Refund Mode
            const Text('Refund Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B))),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedMode,
              isExpanded: true,
              isDense: true,
              onChanged: (v) => setState(() => _selectedMode = v!),
              items: _modes.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Reason
            const Text('Reason', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B))),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedReason,
              isExpanded: true,
              isDense: true,
              onChanged: (v) => setState(() => _selectedReason = v!),
              items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
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
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Find Invoice', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
