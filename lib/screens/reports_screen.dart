import 'dart:math' as math;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// THEME TOKENS
// ---------------------------------------------------------------------------
const _kPrimary = Color(0xFF0F4C81);
const _kAccent = Color(0xFF1976D2);
const _kCardBg = Colors.white;
const _kRadius = 12.0;
const _kGridClr = Color(0xFFEEEEEE);

// ---------------------------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------------------------
class _SalesTrendPoint {
  final String label;
  final double value;
  const _SalesTrendPoint(this.label, this.value);
}

class _TopSellerItem {
  final String name;
  final int qty;
  const _TopSellerItem(this.name, this.qty);
}

class _CategorySlice {
  final String label;
  final double value;
  final Color color;
  const _CategorySlice(this.label, this.value, this.color);
}

class _StatSummary {
  final String label;
  final String value;
  final String change;
  final bool isUp;
  final IconData icon;
  final Color iconColor;
  const _StatSummary({
    required this.label,
    required this.value,
    required this.change,
    required this.isUp,
    required this.icon,
    required this.iconColor,
  });
}

// ---------------------------------------------------------------------------
// DUMMY DATA FACTORY  (swap each TODO block with a Firestore query later)
// ---------------------------------------------------------------------------
Map<String, dynamic> _buildDummyData(String range) {
  // TODO: Replace all dummy generators below with aggregated Firestore queries
  // filtered by the given [range].

  final r = math.Random(range.hashCode);

  // TODO: Replace dummy sales trend data with aggregated Firestore query on
  // 'sales' collection, grouped by date.
  List<_SalesTrendPoint> trend;
  switch (range) {
    case 'Today':
      trend = List.generate(8, (i) {
        final labels = ['9am', '10am', '11am', '12pm', '1pm', '2pm', '3pm', '4pm'];
        return _SalesTrendPoint(labels[i], 2000 + r.nextDouble() * 8000);
      });
      break;
    case 'This Week':
      trend = [
        _SalesTrendPoint('Mon', 14200 + r.nextDouble() * 5000),
        _SalesTrendPoint('Tue', 18900 + r.nextDouble() * 5000),
        _SalesTrendPoint('Wed', 11500 + r.nextDouble() * 5000),
        _SalesTrendPoint('Thu', 22000 + r.nextDouble() * 5000),
        _SalesTrendPoint('Fri', 25300 + r.nextDouble() * 5000),
        _SalesTrendPoint('Sat', 31000 + r.nextDouble() * 5000),
        _SalesTrendPoint('Sun', 9800 + r.nextDouble() * 3000),
      ];
      break;
    case 'This Year':
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      trend = List.generate(12, (i) => _SalesTrendPoint(months[i], 80000 + r.nextDouble() * 120000));
      break;
    default: // This Month
      trend = List.generate(30, (i) => _SalesTrendPoint('${i + 1}', 5000 + r.nextDouble() * 25000));
  }

  // TODO: Replace dummy top-selling medicines with a Firestore aggregation
  // query on 'sales' items, grouped by medicine name, sorted by qty desc.
  final topSellers = [
    _TopSellerItem('Panadol 500mg', 320 + r.nextInt(100)),
    _TopSellerItem('Augmentin 625mg', 210 + r.nextInt(80)),
    _TopSellerItem('Brufen 400mg', 180 + r.nextInt(60)),
    _TopSellerItem('Metformin 500mg', 145 + r.nextInt(50)),
    _TopSellerItem('Ciplox 500mg', 98 + r.nextInt(40)),
  ];

  // TODO: Replace dummy category breakdown with a Firestore aggregation
  // grouped by medicine category.
  final categories = [
    _CategorySlice('Tablets', 42 + r.nextDouble() * 8, const Color(0xFF0F4C81)),
    _CategorySlice('Syrups', 22 + r.nextDouble() * 5, const Color(0xFF1976D2)),
    _CategorySlice('Injections', 14 + r.nextDouble() * 4, const Color(0xFF42A5F5)),
    _CategorySlice('Capsules', 12 + r.nextDouble() * 4, const Color(0xFF90CAF9)),
    _CategorySlice('Others', 10 + r.nextDouble() * 3, const Color(0xFFBBDEFB)),
  ];

  final totalRevenue = trend.fold(0.0, (s, p) => s + p.value);
  final totalSales = 180 + r.nextInt(80);
  final totalItems = 420 + r.nextInt(200);
  final avgSale = totalRevenue / totalSales;
  final changeSign = r.nextBool();

  final stats = [
    _StatSummary(
      label: 'Total Revenue',
      value: 'Rs. ${_formatNum(totalRevenue)}',
      change: '${changeSign ? '+' : '-'}${(r.nextDouble() * 15 + 2).toStringAsFixed(1)}%',
      isUp: changeSign,
      icon: Icons.attach_money_rounded,
      iconColor: _kPrimary,
    ),
    _StatSummary(
      label: 'Total Sales',
      value: totalSales.toString(),
      change: '${r.nextBool() ? '+' : '-'}${(r.nextDouble() * 12 + 1).toStringAsFixed(1)}%',
      isUp: r.nextBool(),
      icon: Icons.receipt_long_outlined,
      iconColor: _kAccent,
    ),
    _StatSummary(
      label: 'Items Sold',
      value: totalItems.toString(),
      change: '+${(r.nextDouble() * 10 + 1).toStringAsFixed(1)}%',
      isUp: true,
      icon: Icons.medication_outlined,
      iconColor: const Color(0xFF2E7D32),
    ),
    _StatSummary(
      label: 'Avg Sale Value',
      value: 'Rs. ${_formatNum(avgSale)}',
      change: '${r.nextBool() ? '+' : '-'}${(r.nextDouble() * 8 + 1).toStringAsFixed(1)}%',
      isUp: r.nextBool(),
      icon: Icons.trending_up_rounded,
      iconColor: const Color(0xFF7B1FA2),
    ),
  ];

  return {
    'trend': trend,
    'topSellers': topSellers,
    'categories': categories,
    'stats': stats,
  };
}

String _formatNum(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
  return v.toStringAsFixed(0);
}

// ---------------------------------------------------------------------------
// REPORTS SCREEN
// ---------------------------------------------------------------------------
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _ranges = ['Today', 'This Week', 'This Month', 'This Year', 'Custom Range'];
  String _selectedRange = 'This Month';
  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = _buildDummyData(_selectedRange);
  }

  void _onRangeChanged(String? v) {
    if (v == null || v == _selectedRange) return;
    if (v == 'Custom Range') {
      // TODO: Show a DateRangePicker dialog for custom range selection
      return;
    }
    setState(() {
      _selectedRange = v;
      _data = _buildDummyData(v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = _data['stats'] as List<_StatSummary>;
    final trend = _data['trend'] as List<_SalesTrendPoint>;
    final topSellers = _data['topSellers'] as List<_TopSellerItem>;
    final categories = _data['categories'] as List<_CategorySlice>;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page Header ──────────────────────────────────────────────────
          _PageHeader(
            selectedRange: _selectedRange,
            ranges: _ranges,
            onRangeChanged: _onRangeChanged,
          ),

          const SizedBox(height: 24),

          // ── Summary Stats ────────────────────────────────────────────────
          _StatsRow(stats: stats),

          const SizedBox(height: 24),

          // ── Sales Trend (full width) ─────────────────────────────────────
          _SalesTrendCard(key: ValueKey(_selectedRange), trendData: trend),

          const SizedBox(height: 24),

          // ── Top Sellers + Category Breakdown ────────────────────────────
          LayoutBuilder(
            builder: (_, constraints) {
              if (constraints.maxWidth < 760) {
                return Column(
                  children: [
                    _TopSellersCard(key: ValueKey('ts$_selectedRange'), items: topSellers),
                    const SizedBox(height: 24),
                    _CategoryBreakdownCard(key: ValueKey('cat$_selectedRange'), slices: categories),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 55,
                    child: _TopSellersCard(key: ValueKey('ts$_selectedRange'), items: topSellers),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 45,
                    child: _CategoryBreakdownCard(key: ValueKey('cat$_selectedRange'), slices: categories),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAGE HEADER
// ---------------------------------------------------------------------------
class _PageHeader extends StatelessWidget {
  final String selectedRange;
  final List<String> ranges;
  final ValueChanged<String?> onRangeChanged;

  const _PageHeader({
    required this.selectedRange,
    required this.ranges,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Title + subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reports',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2E2B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track your pharmacy\'s performance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Export button
        // TODO: Implement actual PDF/CSV export logic for the Export Report button
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download_outlined, size: 16),
          label: const Text('Export Report'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kPrimary,
            side: const BorderSide(color: _kPrimary, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),

        // Date range dropdown
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_kRadius),
            border: Border.all(color: const Color(0xFFDDE3EF), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedRange,
              items: ranges
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(
                          r,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A2E2B),
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: onRangeChanged,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kPrimary, size: 20),
              borderRadius: BorderRadius.circular(_kRadius),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// STATS ROW
// ---------------------------------------------------------------------------
class _StatsRow extends StatelessWidget {
  final List<_StatSummary> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats.asMap().entries.map((e) {
        final idx = e.key;
        final s = e.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: idx < stats.length - 1 ? 16 : 0),
            child: _StatCardWithTrend(summary: s),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// STAT CARD WITH TREND
// ---------------------------------------------------------------------------
class _StatCardWithTrend extends StatelessWidget {
  final _StatSummary summary;
  const _StatCardWithTrend({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(_kRadius + 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: summary.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: summary.iconColor.withValues(alpha: 0.15),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(summary.icon, color: summary.iconColor, size: 22),
              ),
              // Trend pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: summary.isUp
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      summary.isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 12,
                      color: summary.isUp ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      summary.change,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: summary.isUp ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            summary.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary.value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2E2B),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SALES TREND CARD
// ---------------------------------------------------------------------------
class _SalesTrendCard extends StatefulWidget {
  final List<_SalesTrendPoint> trendData;
  const _SalesTrendCard({super.key, required this.trendData});

  @override
  State<_SalesTrendCard> createState() => _SalesTrendCardState();
}

class _SalesTrendCardState extends State<_SalesTrendCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;
  Offset? _hoverPos;
  int? _hoverIndex;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Sales Trend',
      subtitle: 'Revenue over selected period',
      icon: Icons.show_chart_rounded,
      child: SizedBox(
        height: 260,
        child: AnimatedBuilder(
          animation: _progress,
          builder: (context, child) {
            return MouseRegion(
              onHover: (event) {
                setState(() => _hoverPos = event.localPosition);
              },
              onExit: (_) => setState(() {
                _hoverPos = null;
                _hoverIndex = null;
              }),
              child: widget.trendData.isEmpty
                  ? const _EmptyState(message: 'No data for this period')
                  : CustomPaint(
                      painter: _LineChartPainter(
                        points: widget.trendData,
                        progress: _progress.value,
                        hoverPos: _hoverPos,
                        onHoverIndex: (i) {
                          if (_hoverIndex != i) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => _hoverIndex = i);
                            });
                          }
                        },
                      ),
                      child: Container(),
                    ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LINE CHART PAINTER
// ---------------------------------------------------------------------------
class _LineChartPainter extends CustomPainter {
  final List<_SalesTrendPoint> points;
  final double progress;
  final Offset? hoverPos;
  final ValueChanged<int?> onHoverIndex;

  static const double _padL = 60;
  static const double _padR = 24;
  static const double _padT = 16;
  static const double _padB = 40;

  _LineChartPainter({
    required this.points,
    required this.progress,
    required this.hoverPos,
    required this.onHoverIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final w = size.width;
    final h = size.height;
    final chartW = w - _padL - _padR;
    final chartH = h - _padT - _padB;

    final maxVal = points.map((p) => p.value).reduce(math.max);
    final minVal = points.map((p) => p.value).reduce(math.min) * 0.85;
    final range = (maxVal - minVal).clamp(1, double.infinity);

    // Compute pixel positions
    List<Offset> pts = [];
    for (int i = 0; i < points.length; i++) {
      final x = _padL + (i / (points.length - 1)) * chartW;
      final y = _padT + chartH - ((points[i].value - minVal) / range) * chartH;
      pts.add(Offset(x, y));
    }

    // ── Gridlines ──────────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = _kGridClr
      ..strokeWidth = 1;
    const gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      final y = _padT + (chartH / gridLines) * i;
      canvas.drawLine(Offset(_padL, y), Offset(w - _padR, y), gridPaint);

      // Y-axis labels
      final val = maxVal - (range / gridLines) * i;
      final tp = TextPainter(
        text: TextSpan(
          text: _formatNum(val),
          style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(_padL - tp.width - 6, y - tp.height / 2));
    }

    // ── X-axis labels ────────────────────────────────────────────────────
    const maxLabels = 10;
    final step = (points.length / maxLabels).ceil();
    for (int i = 0; i < points.length; i++) {
      if (i % step != 0 && i != points.length - 1) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: points[i].label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pts[i].dx - tp.width / 2, h - _padB + 8));
    }

    // ── Animated clip rect ──────────────────────────────────────────────
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, _padL + chartW * progress + 1, h));

    // ── Fill gradient below line ─────────────────────────────────────────
    final fillPath = Path();
    fillPath.moveTo(pts[0].dx, _padT + chartH);
    for (final p in pts) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(pts.last.dx, _padT + chartH);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_kPrimary.withValues(alpha: 0.15), _kPrimary.withValues(alpha: 0.01)],
      ).createShader(Rect.fromLTWH(_padL, _padT, chartW, chartH));
    canvas.drawPath(fillPath, fillPaint);

    // ── Line ────────────────────────────────────────────────────────────
    final linePath = Path();
    linePath.moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      // Smooth cubic bezier
      final cp1 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i - 1].dy);
      final cp2 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i].dx, pts[i].dy);
    }

    final linePaint = Paint()
      ..color = _kPrimary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    canvas.restore();

    // ── Dots ─────────────────────────────────────────────────────────────
    final dotPaint = Paint()..color = _kPrimary;
    final dotBg = Paint()..color = Colors.white;
    for (int i = 0; i < pts.length; i++) {
      if (pts[i].dx > _padL + chartW * progress + 2) break;
      canvas.drawCircle(pts[i], 5, dotBg);
      canvas.drawCircle(pts[i], 3.5, dotPaint);
    }

    // ── Hover detection + tooltip ────────────────────────────────────────
    if (hoverPos != null) {
      double minDist = double.infinity;
      int closestIdx = -1;
      for (int i = 0; i < pts.length; i++) {
        if (pts[i].dx > _padL + chartW * progress + 2) break;
        final dist = (pts[i].dx - hoverPos!.dx).abs();
        if (dist < minDist) {
          minDist = dist;
          closestIdx = i;
        }
      }
      onHoverIndex(closestIdx >= 0 ? closestIdx : null);

      if (closestIdx >= 0 && minDist < chartW / (points.length - 1) * 0.7) {
        final pt = pts[closestIdx];
        // Hover highlight circle
        canvas.drawCircle(pt, 7, Paint()..color = _kPrimary.withValues(alpha: 0.18));
        canvas.drawCircle(pt, 5, Paint()..color = Colors.white);
        canvas.drawCircle(pt, 3.5, Paint()..color = _kPrimary);

        // Tooltip
        final label = '${points[closestIdx].label}\nRs. ${_formatNum(points[closestIdx].value)}';
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        const pad = 8.0;
        final boxW = tp.width + pad * 2;
        final boxH = tp.height + pad * 2;
        double boxX = pt.dx - boxW / 2;
        double boxY = pt.dy - boxH - 14;
        boxX = boxX.clamp(0, w - boxW);
        boxY = boxY.clamp(0, h - boxH);

        final rr = RRect.fromRectAndRadius(
          Rect.fromLTWH(boxX, boxY, boxW, boxH),
          const Radius.circular(8),
        );
        canvas.drawRRect(rr, Paint()..color = const Color(0xFF1A2E2B));
        tp.paint(canvas, Offset(boxX + pad, boxY + pad));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.progress != progress || old.hoverPos != hoverPos || old.points != points;
}

// ---------------------------------------------------------------------------
// TOP SELLERS CARD
// ---------------------------------------------------------------------------
class _TopSellersCard extends StatefulWidget {
  final List<_TopSellerItem> items;
  const _TopSellersCard({super.key, required this.items});

  @override
  State<_TopSellersCard> createState() => _TopSellersCardState();
}

class _TopSellersCardState extends State<_TopSellersCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxQty = widget.items.isEmpty ? 1 : widget.items.map((i) => i.qty).reduce(math.max);
    return _SectionCard(
      title: 'Top Selling Medicines',
      subtitle: 'By quantity sold',
      icon: Icons.medication_outlined,
      child: widget.items.isEmpty
          ? const _EmptyState(message: 'No sales data for this period')
          : AnimatedBuilder(
              animation: _progress,
              builder: (context, child) {
                return Column(
                  children: widget.items.asMap().entries.map((e) {
                    final delay = e.key * 0.15;
                    final animVal = (_progress.value - delay).clamp(0.0, 1.0) / (1 - delay.clamp(0.0, 0.99));
                    return _TopSellerBar(
                      item: e.value,
                      fraction: (e.value.qty / maxQty) * animVal.clamp(0.0, 1.0),
                      rank: e.key + 1,
                    );
                  }).toList(),
                );
              },
            ),
    );
  }
}

class _TopSellerBar extends StatefulWidget {
  final _TopSellerItem item;
  final double fraction;
  final int rank;

  const _TopSellerBar({required this.item, required this.fraction, required this.rank});

  @override
  State<_TopSellerBar> createState() => _TopSellerBarState();
}

class _TopSellerBarState extends State<_TopSellerBar> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final barColor = Color.lerp(_kPrimary, _kAccent, (widget.rank - 1) / 4)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? barColor.withValues(alpha: 0.04) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${widget.rank}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2E2B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    LayoutBuilder(
                      builder: (_, c) => Stack(
                        children: [
                          Container(
                            height: 6,
                            width: c.maxWidth,
                            decoration: BoxDecoration(
                              color: barColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            height: 6,
                            width: c.maxWidth * widget.fraction,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [barColor, barColor.withValues(alpha: 0.7)],
                              ),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: barColor.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${widget.item.qty}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CATEGORY BREAKDOWN CARD
// ---------------------------------------------------------------------------
class _CategoryBreakdownCard extends StatefulWidget {
  final List<_CategorySlice> slices;
  const _CategoryBreakdownCard({super.key, required this.slices});

  @override
  State<_CategoryBreakdownCard> createState() => _CategoryBreakdownCardState();
}

class _CategoryBreakdownCardState extends State<_CategoryBreakdownCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;
  int? _hoverIndex;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.slices.fold(0.0, (s, sl) => s + sl.value);

    return _SectionCard(
      title: 'Category Breakdown',
      subtitle: 'Sales split by medicine type',
      icon: Icons.pie_chart_outline_rounded,
      child: widget.slices.isEmpty
          ? const _EmptyState(message: 'No category data for this period')
          : AnimatedBuilder(
              animation: _progress,
              builder: (context, child) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Donut chart
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CustomPaint(
                        painter: _DonutChartPainter(
                          slices: widget.slices,
                          progress: _progress.value,
                          hoverIndex: _hoverIndex,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Legend
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.slices.asMap().entries.map((e) {
                          final idx = e.key;
                          final sl = e.value;
                          final pct = (sl.value / total * 100).toStringAsFixed(1);
                          return MouseRegion(
                            onEnter: (_) => setState(() => _hoverIndex = idx),
                            onExit: (_) => setState(() => _hoverIndex = null),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: sl.color,
                                      shape: BoxShape.circle,
                                      boxShadow: _hoverIndex == idx
                                          ? [BoxShadow(color: sl.color.withValues(alpha: 0.5), blurRadius: 6)]
                                          : [],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      sl.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: _hoverIndex == idx ? FontWeight.w700 : FontWeight.w500,
                                        color: const Color(0xFF3D3D3D),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$pct%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: sl.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// DONUT CHART PAINTER
// ---------------------------------------------------------------------------
class _DonutChartPainter extends CustomPainter {
  final List<_CategorySlice> slices;
  final double progress;
  final int? hoverIndex;

  _DonutChartPainter({
    required this.slices,
    required this.progress,
    required this.hoverIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;

    final total = slices.fold(0.0, (s, sl) => s + sl.value);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeW = 24.0;
    const gap = 0.025; // radians between segments

    double startAngle = -math.pi / 2;

    for (int i = 0; i < slices.length; i++) {
      final sweep = (slices[i].value / total) * 2 * math.pi * progress;
      if (sweep < 0.01) { startAngle += sweep; continue; }

      final isHovered = hoverIndex == i;
      final r = isHovered ? radius + 4 : radius;

      final paint = Paint()
        ..color = slices[i].color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? strokeW + 4 : strokeW
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (r - strokeW / 2)),
        startAngle + gap / 2,
        sweep - gap,
        false,
        paint,
      );

      startAngle += sweep;
    }

    // Center label
    final tp = TextPainter(
      text: const TextSpan(
        text: 'Sales\nSplit',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9E9E9E),
          height: 1.5,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter old) =>
      old.progress != progress || old.hoverIndex != hoverIndex || old.slices != slices;
}

// ---------------------------------------------------------------------------
// SECTION CARD WRAPPER
// ---------------------------------------------------------------------------
class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(_kRadius + 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _kPrimary, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2E2B),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EMPTY STATE
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
