import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// THEME TOKENS
// ---------------------------------------------------------------------------
const _kPrimary = Color(0xFF0F4C81);
const _kAccent = Color(0xFF1976D2);
const _kBackground = Color(0xFFF4F7F6);
const _kCardBg = Colors.white;
const _kRadius = 12.0;

// ---------------------------------------------------------------------------
// SETTINGS SCREEN
// ---------------------------------------------------------------------------
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> _tabs = [
    'Profile',
    'Store Information',
    'Notifications',
    'Backup & Sync',
    'Appearance',
    'About',
  ];

  int _selectedTabIndex = 0;

  Widget _buildContent() {
    switch (_selectedTabIndex) {
      case 0:
        return const _ProfileSection();
      case 1:
        return const _StoreInfoSection();
      case 2:
        return const _NotificationsSection();
      case 3:
        return const _BackupSyncSection();
      case 4:
        return const _AppearanceSection();
      case 5:
        return const _AboutSection();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left Sidebar (Tabs) ──────────────────────────────────────────
          SizedBox(
            width: 240,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2E2B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                ...List.generate(
                  _tabs.length,
                  (index) => _SettingsTabItem(
                    label: _tabs[index],
                    isSelected: _selectedTabIndex == index,
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 32),

          // ── Right Content Area ───────────────────────────────────────────
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(_kRadius),
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
              child: SingleChildScrollView(
                child: _buildContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SETTINGS TAB ITEM
// ---------------------------------------------------------------------------
class _SettingsTabItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SettingsTabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SettingsTabItem> createState() => _SettingsTabItemState();
}

class _SettingsTabItemState extends State<_SettingsTabItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? _kPrimary.withValues(alpha: 0.1)
        : _isHovered
            ? Colors.black.withValues(alpha: 0.03)
            : Colors.transparent;

    final textColor = widget.isSelected ? _kPrimary : const Color(0xFF4A4A4A);
    final fontWeight = widget.isSelected ? FontWeight.w700 : FontWeight.w600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(_kRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(_kRadius),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: fontWeight,
                      color: textColor,
                    ),
                  ),
                ),
                if (widget.isSelected)
                  const Icon(Icons.chevron_right, size: 16, color: _kPrimary)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. PROFILE SECTION
// ---------------------------------------------------------------------------
class _ProfileSection extends StatefulWidget {
  const _ProfileSection();

  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  // TODO: Load real profile data from Firebase Auth / Firestore 'users' collection
  final _nameCtrl = TextEditingController(text: 'Admin User');
  final _phoneCtrl = TextEditingController(text: '+92 300 1234567');
  bool _avatarHovered = false;

  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  void _saveProfile() {
    // TODO: Save profile changes to Firestore
    _showSuccess(context, 'Profile updated successfully');
  }

  void _updatePassword() {
    // TODO: Implement real password change via FirebaseAuth.instance.currentUser.updatePassword()
    _showSuccess(context, 'Password updated successfully');
    _currentPwdCtrl.clear();
    _newPwdCtrl.clear();
    _confirmPwdCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader('Profile', 'Manage your personal details and password'),
        const SizedBox(height: 32),

        // Avatar + Role
        Row(
          children: [
            MouseRegion(
              onEnter: (_) => setState(() => _avatarHovered = true),
              onExit: (_) => setState(() => _avatarHovered = false),
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: _kPrimary,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text('A', style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.w700)),
                    if (_avatarHovered)
                      Container(
                        color: Colors.black.withValues(alpha: 0.4),
                        child: const Center(child: Icon(Icons.camera_alt, color: Colors.white)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Admin',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                ),
                const SizedBox(height: 8),
                Text('admin@sohailmedical.com', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
            )
          ],
        ),
        const SizedBox(height: 32),

        _TextFieldRow('Full Name', _nameCtrl),
        const SizedBox(height: 16),
        _TextFieldRow('Phone Number', _phoneCtrl),
        const SizedBox(height: 24),

        _SaveButton(onPressed: _saveProfile),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Divider(color: Color(0xFFEEEEEE)),
        ),

        const Text('Change Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
        const SizedBox(height: 24),
        _TextFieldRow('Current Password', _currentPwdCtrl, obscureText: true),
        const SizedBox(height: 16),
        _TextFieldRow('New Password', _newPwdCtrl, obscureText: true),
        const SizedBox(height: 16),
        _TextFieldRow('Confirm Password', _confirmPwdCtrl, obscureText: true),
        const SizedBox(height: 24),
        _SaveButton(label: 'Update Password', onPressed: _updatePassword),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 2. STORE INFORMATION SECTION
// ---------------------------------------------------------------------------
class _StoreInfoSection extends StatefulWidget {
  const _StoreInfoSection();

  @override
  State<_StoreInfoSection> createState() => _StoreInfoSectionState();
}

class _StoreInfoSectionState extends State<_StoreInfoSection> {
  // TODO: Load real store details from Firestore
  final _nameCtrl = TextEditingController(text: 'Sohail Medical Store');
  final _addressCtrl = TextEditingController(text: 'Main Market, Gulberg\nLahore, Pakistan');
  final _phoneCtrl = TextEditingController(text: '+92 42 1234567');
  final _licenseCtrl = TextEditingController(text: 'DRAP-LHR-2023-0941');

  void _saveStoreInfo() {
    _showSuccess(context, 'Store information saved');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader('Store Information', 'Update the details displayed on your invoices and reports'),
        const SizedBox(height: 32),
        _TextFieldRow('Store Name', _nameCtrl),
        const SizedBox(height: 16),
        _TextFieldRow('Address', _addressCtrl, maxLines: 3),
        const SizedBox(height: 16),
        _TextFieldRow('Phone Number', _phoneCtrl),
        const SizedBox(height: 16),
        _TextFieldRow('License / Registration No.', _licenseCtrl),
        const SizedBox(height: 24),
        _SaveButton(onPressed: _saveStoreInfo),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3. NOTIFICATIONS SECTION
// ---------------------------------------------------------------------------
class _NotificationsSection extends StatefulWidget {
  const _NotificationsSection();

  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
  // TODO: Persist notification preferences locally (e.g. via shared_preferences)
  bool _lowStock = true;
  bool _dailySales = false;
  bool _newCustomer = true;
  bool _expiryWarnings = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader('Notifications', 'Control what alerts and emails you receive'),
        const SizedBox(height: 32),
        _ToggleRow(
          title: 'Low Stock Alerts',
          subtitle: 'Get notified when an item falls below its minimum stock threshold.',
          value: _lowStock,
          onChanged: (v) => setState(() => _lowStock = v),
        ),
        _ToggleRow(
          title: 'Expiry Date Warnings',
          subtitle: 'Alerts for medicines expiring within the next 30 days.',
          value: _expiryWarnings,
          onChanged: (v) => setState(() => _expiryWarnings = v),
        ),
        _ToggleRow(
          title: 'Daily Sales Summary',
          subtitle: 'Receive a daily email summarizing total sales and revenue.',
          value: _dailySales,
          onChanged: (v) => setState(() => _dailySales = v),
        ),
        _ToggleRow(
          title: 'New Customer Registered',
          subtitle: 'Notify me when a new customer profile is created.',
          value: _newCustomer,
          onChanged: (v) => setState(() => _newCustomer = v),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4. BACKUP & SYNC SECTION
// ---------------------------------------------------------------------------
class _BackupSyncSection extends StatefulWidget {
  const _BackupSyncSection();

  @override
  State<_BackupSyncSection> createState() => _BackupSyncSectionState();
}

class _BackupSyncSectionState extends State<_BackupSyncSection> {
  // TODO: Persist toggle and wire sync logic to push local SQLite data to Firestore
  bool _autoSync = true;
  bool _isSyncing = false;
  String _lastSynced = 'Today at 02:45 PM';

  void _syncNow() async {
    setState(() => _isSyncing = true);
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isSyncing = false;
        _lastSynced = 'Just now';
      });
      _showSuccess(context, 'Data synced successfully to the cloud.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader('Backup & Sync', 'Manage your local data and cloud synchronization'),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _kBackground,
            borderRadius: BorderRadius.circular(_kRadius),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              Icon(Icons.cloud_done_outlined, size: 32, color: Colors.green.shade600),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cloud Sync Status',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last synced: $_lastSynced',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSyncing ? null : _syncNow,
                icon: _isSyncing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.sync, size: 18),
                label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
                  elevation: 0,
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 32),
        _ToggleRow(
          title: 'Auto-sync when online',
          subtitle: 'Your data is saved locally first and automatically synced to the cloud when you\'re connected to the internet.',
          value: _autoSync,
          onChanged: (v) => setState(() => _autoSync = v),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5. APPEARANCE SECTION
// ---------------------------------------------------------------------------
class _AppearanceSection extends StatefulWidget {
  const _AppearanceSection();

  @override
  State<_AppearanceSection> createState() => _AppearanceSectionState();
}

class _AppearanceSectionState extends State<_AppearanceSection> {
  // TODO: Implement actual theme provider switching and font scaling
  String _themeMode = 'Light';
  double _fontSize = 1.0; // 0 = Small, 1 = Medium, 2 = Large

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader('Appearance', 'Customize how Sohail Medical Store looks on your device'),
        const SizedBox(height: 32),

        const Text('Theme Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B))),
        const SizedBox(height: 12),
        Row(
          children: ['Light', 'Dark', 'System'].map((mode) {
            final isSelected = _themeMode == mode;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () => setState(() => _themeMode = mode),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? _kPrimary.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? _kPrimary : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        mode == 'Light' ? Icons.light_mode_outlined : mode == 'Dark' ? Icons.dark_mode_outlined : Icons.settings_system_daydream_outlined,
                        size: 16,
                        color: isSelected ? _kPrimary : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mode,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? _kPrimary : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 32),

        const Text('Font Size', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B))),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _kPrimary,
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: _kPrimary,
            overlayColor: _kPrimary.withValues(alpha: 0.1),
            trackHeight: 4,
          ),
          child: Slider(
            value: _fontSize,
            min: 0,
            max: 2,
            divisions: 2,
            label: _fontSize == 0 ? 'Small' : _fontSize == 1 ? 'Medium' : 'Large',
            onChanged: (v) => setState(() => _fontSize = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('A', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text('A', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
              Text('A', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
            ],
          ),
        )
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 6. ABOUT SECTION
// ---------------------------------------------------------------------------
class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader('About', 'Application information and resources'),
        const SizedBox(height: 32),
        
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.local_pharmacy_rounded, color: _kPrimary, size: 48),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sohail Medical Store',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A2E2B)),
                ),
                const SizedBox(height: 4),
                Text('Version 1.0.0 (Windows Desktop)', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text('Designed & Developed by [Developer Name]', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              ],
            )
          ],
        ),

        const SizedBox(height: 48),

        _LinkRow('Privacy Policy', Icons.privacy_tip_outlined),
        _LinkRow('Terms of Service', Icons.description_outlined),
        _LinkRow('Contact Support', Icons.support_agent_outlined),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String title;
  final IconData icon;

  const _LinkRow(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A2E2B)),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// HELPER WIDGETS
// ---------------------------------------------------------------------------
Widget _SectionHeader(String title, String subtitle) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B)),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
      ),
    ],
  );
}

Widget _TextFieldRow(String label, TextEditingController controller, {int maxLines = 1, bool obscureText = false}) {
  return Row(
    crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
    children: [
      SizedBox(
        width: 180,
        child: Padding(
          padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A)),
          ),
        ),
      ),
      Expanded(
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          obscureText: obscureText,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A2E2B), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: _kBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kRadius),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kRadius),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
          ),
        ),
      ),
    ],
  );
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _kBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(_kRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(_kRadius),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: Colors.white,
                  activeTrackColor: _kPrimary,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade300,
                  trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SaveButton({this.label = 'Save Changes', required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

void _showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
    ),
  );
}
