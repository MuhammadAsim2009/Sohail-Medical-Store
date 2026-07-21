import 'dart:ui';
import '../services/database_helper.dart';
import 'package:flutter/material.dart';
import '../widgets/executive_header.dart';
import 'login_screen.dart';
import 'inventory_screen.dart';
import 'billing_screen.dart';
import 'customers_screen.dart';
import 'suppliers_screen.dart';
import 'ledger_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'purchase_orders_screen.dart';
import 'sales_return_screen.dart';
import 'cashier_management_screen.dart';
import '../services/auth_service.dart';

// ---------------------------------------------------------------------------
// DASHBOARD SCREEN
// ---------------------------------------------------------------------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _AppScreen {
  final String label;
  final IconData icon;
  final Widget screen;
  final bool cashierAllowed;
  const _AppScreen({
    required this.label,
    required this.icon,
    required this.screen,
    this.cashierAllowed = false,
  });
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late List<_AppScreen> _availableScreens;

  @override
  void initState() {
    super.initState();
    final allScreens = [
      _AppScreen(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        screen: _DashboardBody(onNavigate: _navigateToScreen),
        cashierAllowed: true,
      ),
      _AppScreen(
        label: 'Sales (POS)',
        icon: Icons.shopping_cart_outlined,
        screen: const BillingScreen(),
        cashierAllowed: true,
      ),
      _AppScreen(
        label: 'Sales Return',
        icon: Icons.assignment_return_outlined,
        screen: const SalesReturnScreen(),
        cashierAllowed: true,
      ),
      _AppScreen(
        label: 'Inventory',
        icon: Icons.inventory_2_outlined,
        screen: const InventoryScreen(),
        cashierAllowed: true,
      ),
      _AppScreen(
        label: 'Purchases',
        icon: Icons.local_shipping_outlined,
        screen: const PurchaseOrdersScreen(),
      ),
      _AppScreen(
        label: 'Customers',
        icon: Icons.people_outline,
        screen: const CustomersScreen(),
        cashierAllowed: true,
      ),
      _AppScreen(
        label: 'Suppliers',
        icon: Icons.business_outlined,
        screen: const SuppliersScreen(),
      ),
      _AppScreen(
        label: 'Ledger',
        icon: Icons.account_balance_wallet_outlined,
        screen: const LedgerScreen(),
      ),
      _AppScreen(
        label: 'Reports',
        icon: Icons.bar_chart_outlined,
        screen: const ReportsScreen(),
      ),
      _AppScreen(
        label: 'Cashiers',
        icon: Icons.manage_accounts_outlined,
        screen: const CashierManagementScreen(),
      ),
      _AppScreen(
        label: 'Settings',
        icon: Icons.settings_outlined,
        screen: const SettingsScreen(),
      ),
    ];

    _availableScreens = allScreens.where((s) {
      if (AuthService.instance.isAdmin) return true;
      return s.cashierAllowed;
    }).toList();
  }

  void _navigateToScreen(String label) {
    final index = _availableScreens.indexWhere((s) => s.label == label);
    if (index != -1) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [Color(0xFFFFFFFF), Color(0xFFF4F7F6), Color(0xFFE8F0EE)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Row(
          children: [
            // -- Sidebar ----------------------------------------------------
            _Sidebar(
              navItems: _availableScreens
                  .map((s) => _NavItem(label: s.label, icon: s.icon))
                  .toList(),
              selectedIndex: _selectedIndex,
              onItemSelected: (i) => setState(() => _selectedIndex = i),
              onLogout: _handleLogout,
            ),

            // -- Main content area ------------------------------------------
            Expanded(
              child: Column(
                children: [
                  // Scrollable body
                  Expanded(
                    child:
                        _availableScreens[_selectedIndex].label == 'Dashboard'
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _availableScreens[_selectedIndex].screen,
                              ],
                            ),
                          )
                        : _availableScreens[_selectedIndex].screen,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_activity');
    AuthService.instance.clear();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

// ---------------------------------------------------------------------------
// NAV ITEM DATA MODEL
// ---------------------------------------------------------------------------
class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem({required this.label, required this.icon});
}

// ---------------------------------------------------------------------------
// SIDEBAR
// ---------------------------------------------------------------------------
class _Sidebar extends StatefulWidget {
  final List<_NavItem> navItems;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.navItems,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
  });

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  String _shopName = 'New Sohail Medical Store';
  String _shopOwnerName = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void didUpdateWidget(covariant _Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper.instance.getAllSettings();
    if (mounted) {
      setState(() {
        _shopName = settings['shop_name']?.isNotEmpty == true
            ? settings['shop_name']!
            : 'New Sohail Medical Store';
        _shopOwnerName = settings['shop_owner_name']?.isNotEmpty == true
            ? settings['shop_owner_name']!
            : 'Admin';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(color: Color(0xFF0B1120)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Brand header -----------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A66F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _shopName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Enterprise POS Workspace',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),

          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              'OPERATIONS',
              style: TextStyle(
                color: Color(0xFF8F9BB3),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),

          // -- Nav items --------------------------------------------------
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.navItems.length,
              itemBuilder: (_, i) => _SidebarNavItem(
                item: widget.navItems[i],
                isSelected: widget.selectedIndex == i,
                onTap: () => widget.onItemSelected(i),
              ),
            ),
          ),

          // -- Footer Profile ---------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2746).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0B1120),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'A',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _shopOwnerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _shopName,
                          style: const TextStyle(
                            color: Color(0xFF8F9BB3),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: widget.onLogout,
                    child: const Icon(
                      Icons.logout,
                      color: Color(0xFF8F9BB3),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SIDEBAR NAV ITEM
// ---------------------------------------------------------------------------
class _SidebarNavItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isSelected ? Colors.white : const Color(0xFF8F9BB3);
    final labelColor = isSelected ? Colors.white : const Color(0xFF8F9BB3);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.white.withValues(alpha: 0.05),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1E2746) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                if (isSelected)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 3,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(item.icon, color: iconColor, size: 20),
                      const SizedBox(width: 16),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: labelColor,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DASHBOARD BODY
// ---------------------------------------------------------------------------
class _DashboardBody extends StatefulWidget {
  final ValueChanged<String>? onNavigate;
  const _DashboardBody({this.onNavigate});

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await DatabaseHelper.instance.getDashboardData();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurr(double val) =>
      'Rs. ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 100),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final d = _data ?? {};
    final todaySales = d['todaySales'] as double? ?? 0.0;
    final todayNetSale = d['todayNetSale'] as double? ?? 0.0;
    final todayReturn = d['todayReturn'] as double? ?? 0.0;
    final monthlyNetSale = d['monthlyNetSale'] as double? ?? 0.0;
    final receivables = d['receivables'] as double? ?? 0.0;
    final lowStockCount = d['lowStockCount'] as int? ?? 0;

    final stats = [
      _StatData(
        label: 'Today Sales',
        value: _formatCurr(todaySales),
        icon: Icons.point_of_sale_rounded,
        iconBg: const Color(0xFF1565C0),
        trendValue: 'Today',
        isTrendUp: true,
      ),
      _StatData(
        label: 'Today Net Sale',
        value: _formatCurr(todayNetSale),
        icon: Icons.account_balance_wallet_rounded,
        iconBg: const Color(0xFF0F4C81),
        trendValue: 'Today',
        isTrendUp: todayNetSale >= 0,
      ),
      _StatData(
        label: 'Today Return',
        value: _formatCurr(todayReturn),
        icon: Icons.assignment_return_rounded,
        iconBg: const Color(0xFFE65100),
        trendValue: 'Today',
        isTrendUp: false,
      ),
      _StatData(
        label: 'Monthly Net Sale',
        value: _formatCurr(monthlyNetSale),
        icon: Icons.insert_chart_rounded,
        iconBg: const Color(0xFF6A1B9A),
        trendValue: 'This Month',
        isTrendUp: monthlyNetSale >= 0,
      ),
      _StatData(
        label: 'Receivable Dues',
        value: _formatCurr(receivables),
        icon: Icons.request_quote_rounded,
        iconBg: const Color(0xFFD32F2F),
        trendValue: 'All Time',
        isTrendUp: false,
      ),
      _StatData(
        label: 'Low Stock Items',
        value: '$lowStockCount',
        icon: Icons.warning_amber_rounded,
        iconBg: const Color(0xFFEF6C00),
        trendValue: '10 Qty',
        isTrendUp: false,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Executive Header ─────────────────────────────────────────────
        const ExecutiveHeader(),

        const SizedBox(height: 32),

        // ── Stat cards ───────────────────────────────────────────────────
        LayoutBuilder(
          builder: (_, constraints) {
            final crossAxisCount = constraints.maxWidth < 800 ? 2 : 3;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 160,
              ),
              itemCount: stats.length,
              itemBuilder: (_, i) => _StatCard(data: stats[i]),
            );
          },
        ),

        const SizedBox(height: 24),
        const _NearExpiryCard(),

        const SizedBox(height: 24),

        // ── Quick Actions & Sales Trend ──────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _QuickActionsCard(onNavigate: widget.onNavigate),
            const SizedBox(height: 24),
            _SalesTrendCard(trend: (d['trend'] as List<dynamic>?) ?? []),
          ],
        ),

        const SizedBox(height: 24),

        // ── Recent Purchase, Recent Activity, Watchlist ──────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RecentPurchaseTable(
              purchases: (d['recentPurchases'] as List<dynamic>?) ?? [],
            ),
            const SizedBox(height: 24),
            _RecentActivityList(
              activities: (d['recentActivity'] as List<dynamic>?) ?? [],
            ),
            const SizedBox(height: 24),
            _OperationalWatchlist(
              lowStockCount: lowStockCount,
              receivables: receivables,
            ),
          ],
        ),
      ],
    );
  }
} // ---------------------------------------------------------------------------

// STAT DATA MODEL
// ---------------------------------------------------------------------------
class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final String trendValue;
  final bool isTrendUp;
  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.trendValue,
    required this.isTrendUp,
  });
}

// ---------------------------------------------------------------------------
// STAT CARD
// ---------------------------------------------------------------------------
class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon with glowing background
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: data.iconBg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: data.iconBg.withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(data.icon, color: data.iconBg, size: 24),
              ),
              // Trend Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: data.isTrendUp
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      data.isTrendUp
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 14,
                      color: data.isTrendUp
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data.trendValue,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: data.isTrendUp
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
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
// SHARED CARD WIDGET
// ---------------------------------------------------------------------------
class _DashboardCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  const _DashboardCard({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2E2B),
                  ),
                ),
                if (action != null) ...[const Spacer(), action!],
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// QUICK ACTIONS CARD
// ---------------------------------------------------------------------------
class _QuickActionsCard extends StatelessWidget {
  final ValueChanged<String>? onNavigate;
  const _QuickActionsCard({this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Quick Actions',
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.add_shopping_cart,
                    label: 'New Sale',
                    color: const Color(0xFF0F4C81),
                    onTap: () => onNavigate?.call('Sales (POS)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.inventory_2_outlined,
                    label: 'Add Stock',
                    color: const Color(0xFF1565C0),
                    onTap: () => onNavigate?.call('Inventory'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.assignment_return_outlined,
                    label: 'Return',
                    color: const Color(0xFFE65100),
                    onTap: () => onNavigate?.call('Sales Return'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.person_add_alt_1_outlined,
                    label: 'Add Customer',
                    color: const Color(0xFF6A1B9A),
                    onTap: () => onNavigate?.call('Customers'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.local_shipping_outlined,
                    label: 'Add Supplier',
                    color: const Color(0xFF00695C),
                    onTap: () => onNavigate?.call('Suppliers'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.bar_chart_outlined,
                    label: 'View Reports',
                    color: const Color(0xFF455A64),
                    onTap: () => onNavigate?.call('Reports'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: Colors.black.withValues(alpha: 0.02),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1A2E2B),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SALES TREND CARD
// ---------------------------------------------------------------------------
class _SalesTrendCard extends StatelessWidget {
  final List<dynamic> trend;
  const _SalesTrendCard({required this.trend});

  @override
  Widget build(BuildContext context) {
    // Generate simple bars to simulate a trend since fl_chart isn't imported
    final maxTotal = trend.isEmpty
        ? 1.0
        : trend
              .map((e) => (e['total'] as num).toDouble())
              .reduce((a, b) => a > b ? a : b);
    final maxVal = maxTotal == 0 ? 1.0 : maxTotal;

    return _DashboardCard(
      title: 'Sales Trend (Last 7 Days)',
      action: const Icon(Icons.show_chart_rounded, color: Colors.grey),
      child: Container(
        height: 200,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: trend.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No trend data available',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: trend.reversed.map((t) {
                  final date = t['date'] as String;
                  final dateStr =
                      date.substring(8, 10) + '/' + date.substring(5, 7);
                  final total = (t['total'] as num).toDouble();
                  // clamp ratio to [0,1] — guards against negative or NaN totals
                  final heightRatio = (total / maxVal).clamp(0.0, 1.0);
                  // always render at least 2px so the bar is visible
                  final barHeight = (120 * heightRatio).clamp(2.0, 120.0);

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 24,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5A66F9),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RECENT PURCHASE TABLE
// ---------------------------------------------------------------------------
class _RecentPurchaseTable extends StatelessWidget {
  final List<dynamic> purchases;
  const _RecentPurchaseTable({required this.purchases});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Recent Purchases',
      action: TextButton(
        onPressed: () {},
        child: const Text(
          'View All',
          style: TextStyle(
            color: Color(0xFF0F4C81),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: purchases.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No recent purchases',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ),
              )
            : Column(
                children: purchases.map((po) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            size: 20,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                po['supplier'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF1A2E2B),
                                ),
                              ),
                              Text(
                                '${po['po_number']} • ${po['order_date']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Rs. ${(po['total'] as num).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF1A2E2B),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RECENT ACTIVITY LIST
// ---------------------------------------------------------------------------
class _RecentActivityList extends StatelessWidget {
  final List<dynamic> activities;
  const _RecentActivityList({required this.activities});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Recent Activity',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: activities.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No recent activity',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: activities.map((act) {
                  return _ActivityItem(
                    time: act['date'].toString(),
                    text:
                        '${act['type']} - ${act['description']} (Rs. ${(act['amount'] as num).abs().toStringAsFixed(0)})',
                  );
                }).toList(),
              ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String time;
  final String text;

  const _ActivityItem({required this.time, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF0F4C81),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1A2E2B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
// OPERATIONAL WATCHLIST
// ---------------------------------------------------------------------------
class _OperationalWatchlist extends StatelessWidget {
  final int lowStockCount;
  final double receivables;

  const _OperationalWatchlist({
    required this.lowStockCount,
    required this.receivables,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Operational Watchlist',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _WatchlistItem(
              label: 'Pending Receivables',
              value: 'Rs. ${receivables.toStringAsFixed(0)}',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _WatchlistItem(
              label: 'Low Stock Items',
              value: '$lowStockCount',
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            _WatchlistItem(
              label: 'Unpaid Purchases',
              value: 'Check Ledger',
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchlistItem extends StatelessWidget {
  final String label;
  final String value;
  final MaterialColor color;

  const _WatchlistItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: color.shade700),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: color.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color.shade800,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// NEAR-EXPIRY DASHBOARD CARD
// ---------------------------------------------------------------------------
class _NearExpiryCard extends StatefulWidget {
  const _NearExpiryCard();

  @override
  State<_NearExpiryCard> createState() => _NearExpiryCardState();
}

class _NearExpiryCardState extends State<_NearExpiryCard> {
  List<Map<String, dynamic>> _batches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseHelper.instance.getNearExpiryBatches(
      daysAhead: 215,
    );
    if (mounted)
      setState(() {
        _batches = data;
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_batches.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFEDD5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Near-Expiry Alert',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      '${_batches.length} batch${_batches.length == 1 ? '' : 'es'} expiring within 7 Months',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Column headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              children: const [
                Expanded(
                  flex: 4,
                  child: Text(
                    'Product',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Expiry',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Qty',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Days Left',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Rows
          ...List.generate(_batches.length, (i) {
            final b = _batches[i];
            final expiryStr = b['expiry_date'] as String? ?? '';
            final expiryDt = DateTime.tryParse(expiryStr);
            final qty = (b['batch_quantity'] as num).toDouble();
            final now = DateTime.now();
            final daysLeft = expiryDt != null
                ? expiryDt.difference(now).inDays
                : 0;
            final expiryLabel = expiryDt != null
                ? '${expiryDt.day.toString().padLeft(2, '0')}/${expiryDt.month.toString().padLeft(2, '0')}/${expiryDt.year}'
                : '—';
            final Color rowColor = daysLeft <= 0
                ? const Color(0xFFFEF2F2)
                : daysLeft <= 7
                ? const Color(0xFFFFFBEB)
                : Colors.white;
            final Color textColor = daysLeft <= 0
                ? const Color(0xFFEF4444)
                : daysLeft <= 7
                ? const Color(0xFFD97706)
                : const Color(0xFF059669);

            return Container(
              color: i.isEven ? rowColor : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      b['product_name'] as String? ?? '—',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      expiryLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      qty.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
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
                        color: textColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        daysLeft <= 0 ? 'Expired' : '${daysLeft}d',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
