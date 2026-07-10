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
    final dssName = 'DSS-\';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
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
                        '\ closed successfully. Here is the end-of-day summary.',
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
                        Text('\ closed on \', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
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
