import 'dart:ui';
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
import 'purchase_orders_screen.dart';
import 'sales_return_screen.dart';

// ---------------------------------------------------------------------------
// DASHBOARD SCREEN
// ---------------------------------------------------------------------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined),
    _NavItem(label: 'Sales (POS)', icon: Icons.shopping_cart_outlined),
    _NavItem(label: 'Sales Return', icon: Icons.assignment_return_outlined),
    _NavItem(label: 'Inventory', icon: Icons.inventory_2_outlined),
    _NavItem(label: 'Purchases', icon: Icons.local_shipping_outlined),
    _NavItem(label: 'Customers', icon: Icons.people_outline),
    _NavItem(label: 'Suppliers', icon: Icons.business_outlined),
    _NavItem(label: 'Ledger', icon: Icons.account_balance_wallet_outlined),
    _NavItem(label: 'Reports', icon: Icons.bar_chart_outlined),
    _NavItem(label: 'Settings', icon: Icons.settings_outlined),
  ];

  @override
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
            // ── Sidebar ────────────────────────────────────────────────────
            _Sidebar(
              navItems: _navItems,
              selectedIndex: _selectedIndex,
              onItemSelected: (i) => setState(() => _selectedIndex = i),
              onLogout: _handleLogout,
            ),

            // ── Main content area ──────────────────────────────────────────
            Expanded(
              child: Column(
                children: [
                  // Top bar (BillingScreen has its own matching top bar built-in)
                  if (_selectedIndex != 1)
                    _TopBar(
                      pageTitle: _navItems[_selectedIndex].label,
                      pageIcon: _navItems[_selectedIndex].icon,
                    ),

                  // Scrollable body
                  Expanded(
                    child: _selectedIndex == 0
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                            child: _DashboardBody(
                              onNavigate: (index) => setState(() => _selectedIndex = index),
                            ),
                          )
                        : _selectedIndex == 1
                            ? const BillingScreen()
                            : _selectedIndex == 2
                                ? const SalesReturnScreen()
                                : _selectedIndex == 3
                                    ? const InventoryScreen()
                                    : _selectedIndex == 4
                                        ? const PurchaseOrdersScreen()
                                        : _selectedIndex == 5
                                            ? const CustomersScreen()
                                            : _selectedIndex == 6
                                                ? const SuppliersScreen()
                                                : _selectedIndex == 7
                                                    ? const LedgerScreen()
                                                    : _selectedIndex == 8
                                                        ? const ReportsScreen()
                                                        : _selectedIndex == 9
                                                            ? const SettingsScreen()
                                                            : const Center(child: Text('Coming Soon...')),
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
    // TODO: Call FirebaseAuth.instance.signOut() here before navigating.
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
class _Sidebar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xFF0B1120), // Darker navy background matching the image
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Brand header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A66F9), // Purple blue icon bg
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Sohail Medical Store',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
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

          // ── Nav items ──────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: navItems.length,
              itemBuilder: (_, i) => _SidebarNavItem(
                item: navItems[i],
                isSelected: selectedIndex == i,
                onTap: () => onItemSelected(i),
              ),
            ),
          ),

          // ── Footer Profile ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
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
                    child: const Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alee', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('Admin', style: TextStyle(color: Color(0xFF8F9BB3), fontSize: 11)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: onLogout,
                    child: const Icon(Icons.logout, color: Color(0xFF8F9BB3), size: 18),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(item.icon, color: iconColor, size: 20),
                      const SizedBox(width: 16),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: labelColor,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
// TOP BAR
// ---------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  final String pageTitle;
  final IconData pageIcon;

  const _TopBar({required this.pageTitle, required this.pageIcon});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 64, // Sleeker height
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            border: Border(
              bottom: BorderSide(
                color: Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
      child: Row(
        children: [
          // Page title / Breadcrumb
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    'Operations',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    pageTitle,
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Saturday, 27 Jun - Desktop workspace', // Ideally dynamic
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),

          // Search field
          Container(
            width: 280,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.only(left: 12, right: 4),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey.shade400, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search products, invoices, ledgers...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Open', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Notification bell
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
              color: Colors.white,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.notifications_none, size: 20, color: Colors.grey.shade600),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 16),

          // Data synced pill
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade100),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text('Data synced', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Avatar + name
          Container(
            height: 42,
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(color: Color(0xFFE8EAF6), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Text('A', style: TextStyle(color: Color(0xFF5C6BC0), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alee', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.1)),
                    Text('Admin', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, height: 1.1)),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey.shade400),
              ],
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
// DASHBOARD BODY (stats + tables)
// ---------------------------------------------------------------------------
class _DashboardBody extends StatelessWidget {
  final ValueChanged<int>? onNavigate;
  const _DashboardBody({this.onNavigate});

  // TODO: Replace dummy values with Firestore aggregate queries.
  static const _stats = [
    _StatData(
      label: 'Today Sales',
      value: 'Rs. 45,300',
      icon: Icons.point_of_sale_rounded,
      iconBg: Color(0xFF1565C0),
      trendValue: '+14%',
      isTrendUp: true,
    ),
    _StatData(
      label: 'Today Net Sale',
      value: 'Rs. 41,200',
      icon: Icons.account_balance_wallet_rounded,
      iconBg: Color(0xFF0F4C81),
      trendValue: '+12%',
      isTrendUp: true,
    ),
    _StatData(
      label: 'Today Return',
      value: 'Rs. 4,100',
      icon: Icons.assignment_return_rounded,
      iconBg: Color(0xFFE65100),
      trendValue: '-2%',
      isTrendUp: true,
    ),
    _StatData(
      label: 'Monthly Net Sale',
      value: 'Rs. 1,245,000',
      icon: Icons.insert_chart_rounded,
      iconBg: Color(0xFF6A1B9A),
      trendValue: '+8%',
      isTrendUp: true,
    ),
    _StatData(
      label: 'Receivable Dues',
      value: 'Rs. 18,500',
      icon: Icons.request_quote_rounded,
      iconBg: Color(0xFFD32F2F),
      trendValue: '+5%',
      isTrendUp: false,
    ),
    _StatData(
      label: 'Low Stock Item',
      value: '12',
      icon: Icons.warning_amber_rounded,
      iconBg: Color(0xFFEF6C00),
      trendValue: '-3',
      isTrendUp: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                childAspectRatio: constraints.maxWidth < 800 ? 1.6 : 2.2,
              ),
              itemCount: _stats.length,
              itemBuilder: (_, i) => _StatCard(data: _stats[i]),
            );
          },
        ),

        const SizedBox(height: 24),

        // ── Quick Actions & Sales Trend ──────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _QuickActionsCard(onNavigate: onNavigate),
            const SizedBox(height: 24),
            const _SalesTrendCard(),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // ── Recent Purchase, Recent Activity, Watchlist ──────────────────
        const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RecentPurchaseTable(),
            SizedBox(height: 24),
            _RecentActivityList(),
            SizedBox(height: 24),
            _OperationalWatchlist(),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
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
                    )
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
                      data.isTrendUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 14,
                      color: data.isTrendUp ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data.trendValue,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: data.isTrendUp ? Colors.green.shade700 : Colors.red.shade700,
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
                if (action != null) ...[
                  const Spacer(),
                  action!,
                ]
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
  final ValueChanged<int>? onNavigate;
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
                Expanded(child: _ActionBtn(icon: Icons.add_shopping_cart, label: 'New Sale', color: const Color(0xFF0F4C81), onTap: () => onNavigate?.call(2))),
                const SizedBox(width: 8),
                Expanded(child: _ActionBtn(icon: Icons.inventory_2_outlined, label: 'Add Stock', color: const Color(0xFF1565C0), onTap: () => onNavigate?.call(1))),
                const SizedBox(width: 8),
                Expanded(child: _ActionBtn(icon: Icons.assignment_return_outlined, label: 'Return', color: const Color(0xFFE65100), onTap: () => onNavigate?.call(2))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _ActionBtn(icon: Icons.person_add_alt_1_outlined, label: 'Add Customer', color: const Color(0xFF6A1B9A), onTap: () => onNavigate?.call(3))),
                const SizedBox(width: 8),
                Expanded(child: _ActionBtn(icon: Icons.local_shipping_outlined, label: 'Add Supplier', color: const Color(0xFF00695C), onTap: () => onNavigate?.call(4))),
                const SizedBox(width: 8),
                Expanded(child: _ActionBtn(icon: Icons.bar_chart_outlined, label: 'View Reports', color: const Color(0xFF455A64), onTap: () => onNavigate?.call(6))),
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

  const _ActionBtn({required this.icon, required this.label, required this.color, this.onTap});

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
  const _SalesTrendCard();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Sales Trend (Last 7 Days)',
      action: const Icon(Icons.show_chart_rounded, color: Colors.grey),
      child: Container(
        height: 200,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'Chart placeholder\n(Use fl_chart package here)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RECENT PURCHASE TABLE
// ---------------------------------------------------------------------------
class _RecentPurchaseTable extends StatelessWidget {
  const _RecentPurchaseTable();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Recent Purchases',
      action: TextButton(
        onPressed: () {},
        child: const Text('View All', style: TextStyle(color: Color(0xFF0F4C81), fontWeight: FontWeight.w600)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(4, (index) {
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
                    child: const Icon(Icons.receipt_long_rounded, size: 20, color: Colors.blueGrey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Supplier Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A2E2B))),
                        Text('INV-202$index • 2 items', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  const Text('Rs. 12,500', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1A2E2B))),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RECENT ACTIVITY LIST
// ---------------------------------------------------------------------------
class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Recent Activity',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActivityItem(time: '10 mins ago', text: 'New sale recorded (INV-1041)'),
            _ActivityItem(time: '1 hour ago', text: 'Stock added for Panadol 500mg'),
            _ActivityItem(time: '3 hours ago', text: 'Customer return processed'),
            _ActivityItem(time: 'Yesterday', text: 'System backup completed'),
          ],
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
                Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF1A2E2B), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(time, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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
  const _OperationalWatchlist();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Operational Watchlist',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _WatchlistItem(label: 'Pending Deliveries', value: '3', color: Colors.orange),
            const SizedBox(height: 12),
            _WatchlistItem(label: 'Expiring Soon (30 days)', value: '8', color: Colors.red),
            const SizedBox(height: 12),
            _WatchlistItem(label: 'Unpaid Invoices', value: '5', color: Colors.purple),
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

  const _WatchlistItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: color.shade700),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: color.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(value, style: TextStyle(color: color.shade800, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ],
    );
  }
}
