import 'dart:ui';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'inventory_screen.dart';
import 'billing_screen.dart';
import 'customers_screen.dart';
import 'suppliers_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

// ---------------------------------------------------------------------------
// SIMPLE DATA MODELS (replace with Firestore models later)
// ---------------------------------------------------------------------------
class SaleRecord {
  final String invoice;
  final String customer;
  final String medicines;
  final String amount;
  final String date;

  const SaleRecord({
    required this.invoice,
    required this.customer,
    required this.medicines,
    required this.amount,
    required this.date,
  });
}

class LowStockItem {
  final String name;
  final int quantity;
  final bool critical; // true = red, false = orange

  const LowStockItem({
    required this.name,
    required this.quantity,
    required this.critical,
  });
}

// ---------------------------------------------------------------------------
// DUMMY DATA
// ---------------------------------------------------------------------------

// TODO: Replace with real-time stream from Firestore 'sales' collection,
// filtered by date == today
const List<SaleRecord> _dummySales = [
  SaleRecord(
    invoice: 'INV-1041',
    customer: 'Ahmed Raza',
    medicines: 'Panadol, Augmentin',
    amount: 'Rs. 850',
    date: '20 Jun 2026',
  ),
  SaleRecord(
    invoice: 'INV-1040',
    customer: 'Sara Khan',
    medicines: 'Brufen 400mg',
    amount: 'Rs. 320',
    date: '20 Jun 2026',
  ),
  SaleRecord(
    invoice: 'INV-1039',
    customer: 'Hamid Butt',
    medicines: 'Ciplox, ORS Sachet',
    amount: 'Rs. 1,150',
    date: '20 Jun 2026',
  ),
  SaleRecord(
    invoice: 'INV-1038',
    customer: 'Nadia Malik',
    medicines: 'Vitamin C, Zinc',
    amount: 'Rs. 540',
    date: '20 Jun 2026',
  ),
  SaleRecord(
    invoice: 'INV-1037',
    customer: 'Usman Tariq',
    medicines: 'Metformin 500mg',
    amount: 'Rs. 210',
    date: '19 Jun 2026',
  ),
];

// TODO: Replace with Firestore query: medicines where stockQty < minStockThreshold
const List<LowStockItem> _dummyLowStock = [
  LowStockItem(name: 'Panadol 500mg', quantity: 5, critical: true),
  LowStockItem(name: 'Augmentin 625mg', quantity: 8, critical: false),
  LowStockItem(name: 'Brufen 400mg', quantity: 3, critical: true),
  LowStockItem(name: 'ORS Sachet', quantity: 11, critical: false),
  LowStockItem(name: 'Ciplox 500mg', quantity: 2, critical: true),
];

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
    _NavItem(label: 'Inventory', icon: Icons.inventory_2_outlined),
    _NavItem(label: 'Sales / Billing', icon: Icons.point_of_sale_outlined),
    _NavItem(label: 'Customers', icon: Icons.people_outline),
    _NavItem(label: 'Suppliers', icon: Icons.local_shipping_outlined),
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
                  // Top bar
                  _TopBar(
                    pageTitle: _navItems[_selectedIndex].label,
                    pageIcon: _navItems[_selectedIndex].icon,
                  ),

                  // Scrollable body
                  Expanded(
                    child: _selectedIndex == 0
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                            child: _DashboardBody(),
                          )
                        : _selectedIndex == 1
                            ? const InventoryScreen()
                            : _selectedIndex == 2
                                ? const BillingScreen()
                                : _selectedIndex == 3
                                    ? const CustomersScreen()
                                    : _selectedIndex == 4
                                        ? const SuppliersScreen()
                                        : _selectedIndex == 5
                                            ? const ReportsScreen()
                                            : _selectedIndex == 6
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
        color: Color(0xFF0F4C81),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Brand header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 28),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3), width: 1),
                  ),
                  child: const Icon(Icons.local_pharmacy_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sohail Medical',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Store',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.70),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 12),

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

          Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),

          // ── Logout ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: _SidebarNavItem(
              item: const _NavItem(label: 'Logout', icon: Icons.logout_rounded),
              isSelected: false,
              isDestructive: true,
              onTap: onLogout,
            ),
          ),
          const SizedBox(height: 8),
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
  final bool isDestructive;

  const _SidebarNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDestructive
        ? Colors.red.shade200
        : isSelected
            ? Colors.white
            : Colors.white.withValues(alpha: 0.65);

    final labelColor = isDestructive
        ? Colors.red.shade200
        : isSelected
            ? Colors.white
            : Colors.white.withValues(alpha: 0.65);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          hoverColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.transparent,
              border: isSelected
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.4), width: 1.5)
                  : Border.all(color: Colors.transparent, width: 1.5),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.1),
                        blurRadius: 8,
                        spreadRadius: -2,
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Icon(item.icon, color: iconColor, size: 22),
                const SizedBox(width: 14),
                Text(
                  item.label,
                  style: TextStyle(
                    color: labelColor,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
                if (isSelected && !isDestructive) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
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
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
      child: Row(
        children: [
          // Page title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F4C81).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  pageIcon,
                  color: const Color(0xFF0F4C81),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                pageTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A2E2B),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Search field
          SizedBox(
            width: 220,
            height: 38,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search…',
                hintStyle: TextStyle(
                    color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: Icon(Icons.search,
                    color: Colors.grey.shade400, size: 18),
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: const Color(0xFFF4F7F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Notification bell
          IconButton(
            icon: Badge(
              label: const Text('3'),
              child: const Icon(Icons.notifications_outlined, size: 22),
            ),
            color: Colors.grey.shade600,
            tooltip: 'Notifications',
            onPressed: () {},
          ),
          const SizedBox(width: 4),

          // Avatar + name
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFF0F4C81),
                child: const Text(
                  'A',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Admin User',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey.shade700,
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
// DASHBOARD BODY (stats + tables)
// ---------------------------------------------------------------------------
class _DashboardBody extends StatelessWidget {
  // TODO: Replace dummy values with Firestore aggregate queries.
  static const _stats = [
    _StatData(
      label: 'Total Medicines',
      value: '1,248',
      icon: Icons.medication_outlined,
      iconBg: const Color(0xFF0F4C81),
      trendValue: '+2.4%',
      isTrendUp: true,
    ),
    _StatData(
      label: "Today's Sales",
      value: 'Rs. 45,300',
      icon: Icons.attach_money_rounded,
      iconBg: Color(0xFF1565C0),
      trendValue: '+14%',
      isTrendUp: true,
    ),
    _StatData(
      label: 'Low Stock Items',
      value: '12',
      icon: Icons.warning_amber_rounded,
      iconBg: Color(0xFFE65100),
      trendValue: '-3',
      isTrendUp: true, // fewer low stock items is good
    ),
    _StatData(
      label: 'Total Customers',
      value: '320',
      icon: Icons.people_alt_outlined,
      iconBg: Color(0xFF6A1B9A),
      trendValue: '+8%',
      isTrendUp: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stat cards ───────────────────────────────────────────────────
        LayoutBuilder(
          builder: (_, constraints) {
            if (constraints.maxWidth < 600) {
              // Narrow: 2-column grid
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.6,
                ),
                itemCount: _stats.length,
                itemBuilder: (_, i) => _StatCard(data: _stats[i]),
              );
            }
            return Row(
              children: _stats
                  .map((d) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: d != _stats.last ? 16 : 0),
                          child: _StatCard(data: d),
                        ),
                      ))
                  .toList(),
            );
          },
        ),

        const SizedBox(height: 24),

        // ── Recent sales + low stock ─────────────────────────────────────
        LayoutBuilder(
          builder: (_, constraints) {
            if (constraints.maxWidth < 700) {
              return const Column(
                children: [
                  _RecentSalesTable(),
                  SizedBox(height: 20),
                  _LowStockList(),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(flex: 65, child: _RecentSalesTable()),
                SizedBox(width: 20),
                Expanded(flex: 35, child: _LowStockList()),
              ],
            );
          },
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
          const SizedBox(height: 24),
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
// RECENT SALES TABLE
// ---------------------------------------------------------------------------
class _RecentSalesTable extends StatelessWidget {
  const _RecentSalesTable();

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
          // Card header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Text(
                  'Recent Sales',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2E2B),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All',
                      style: TextStyle(
                          color: const Color(0xFF0F4C81),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),

          // Table header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _tableHeader('Invoice #', flex: 2),
                _tableHeader('Customer', flex: 3),
                _tableHeader('Medicine(s)', flex: 4),
                _tableHeader('Amount', flex: 2),
                _tableHeader('Date', flex: 2),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),

          // Rows
          // TODO: Replace _dummySales with Firestore query:
          // FirebaseFirestore.instance.collection('sales')
          //   .orderBy('createdAt', descending: true).limit(10).get()
          ...List.generate(_dummySales.length, (i) {
            final sale = _dummySales[i];
            final isEven = i % 2 == 0;
            return Material(
              color: isEven ? Colors.transparent : const Color(0xFFF9FAFA),
              child: InkWell(
                onTap: () {}, // Add hover effect
                hoverColor: Colors.blueGrey.shade50.withValues(alpha: 0.5),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      _tableCell(sale.invoice,
                          flex: 2,
                          style: const TextStyle(
                              color: const Color(0xFF0F4C81),
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      _tableCell(sale.customer, 
                          flex: 3,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF1A2E2B))),
                      _tableCell(sale.medicines, flex: 4),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              sale.amount,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, 
                                  fontSize: 12,
                                  color: Colors.green.shade700),
                            ),
                          ),
                        ),
                      ),
                      _tableCell(sale.date,
                          flex: 2,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _tableHeader(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade400,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _tableCell(String text,
      {required int flex, TextStyle? style}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: style ??
            const TextStyle(fontSize: 13, color: Color(0xFF2D3A38)),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LOW STOCK LIST
// ---------------------------------------------------------------------------
class _LowStockList extends StatelessWidget {
  const _LowStockList();

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
          // Card header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFE65100), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Low Stock Alerts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2E2B),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBE0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_dummyLowStock.length}',
                    style: const TextStyle(
                      color: Color(0xFFE65100),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),

          // TODO: Replace _dummyLowStock with Firestore query:
          // FirebaseFirestore.instance.collection('medicines')
          //   .where('stockQty', isLessThan: minThreshold).get()
          ...List.generate(_dummyLowStock.length, (i) {
            final item = _dummyLowStock[i];
            final badgeColor =
                item.critical ? const Color(0xFFD32F2F) : const Color(0xFFE65100);
            final badgeBg = item.critical
                ? const Color(0xFFFFEBEE)
                : const Color(0xFFFFEBE0);
            final isLast = i == _dummyLowStock.length - 1;

            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item.critical ? badgeColor.withValues(alpha: 0.3) : Colors.grey.shade200,
                      width: 1,
                    ),
                    color: item.critical 
                      ? badgeColor.withValues(alpha: 0.04) 
                      : Colors.white,
                  ),
                  child: Row(
                    children: [
                      // Left colored indicator
                      Container(
                        width: 4,
                        height: 50,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A2E2B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(right: 32),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: item.quantity / 20.0, // Assuming 20 is max threshold
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                                  minHeight: 5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: badgeColor.withValues(alpha: 0.3),
                              width: 1),
                        ),
                        child: Text(
                          '${item.quantity} left',
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
                if (!isLast)
                  const SizedBox(height: 2),
              ],
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
