import 'package:flutter/material.dart';
import '../widgets/executive_header.dart';

// ---------------------------------------------------------------------------
// THEME TOKENS
// ---------------------------------------------------------------------------
const _kPrimary = Color(0xFF5A66F9); // Purple-ish primary from the image
const _kBackground = Color(0xFFF4F7F6);
const _kCardBg = Colors.white;
const _kRadius = 12.0;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExecutiveHeader(title: 'Settings', subtitle: 'Manage store preferences, user accounts, backup, and sync configuration.'),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column - General Settings
                Expanded(
                  flex: 5,
                  child: _SettingsCard(
                    title: 'General Settings',
                    child: const _GeneralSettingsContent(),
                  ),
                ),
                const SizedBox(width: 24),
                // Right Column - Backup and Password
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      _SettingsCard(
                        title: 'Backup & Restore',
                        child: const _BackupRestoreContent(),
                      ),
                      const SizedBox(height: 24),
                      _SettingsCard(
                        title: 'Change Password',
                        child: const _ChangePasswordContent(),
                      ),
                    ],
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

class _SettingsCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _GeneralSettingsContent extends StatelessWidget {
  const _GeneralSettingsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildField(
          label: 'Shop Name',
          hint: 'e.g. Sohail Medical Store',
          icon: Icons.store_mall_directory_outlined,
        ),
        const SizedBox(height: 20),
        _buildField(
          label: 'Shop Address',
          hint: 'e.g. Main Market, Lahore',
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 20),
        _buildField(
          label: 'Shop Phone',
          hint: '+92 300 1234567',
          icon: Icons.phone_outlined,
        ),
        const SizedBox(height: 20),
        _buildField(
          label: 'Tax Rate',
          hint: '0',
          prefixText: '%   ',
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({required String label, required String hint, IconData? icon, String? prefixText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            prefixIcon: icon != null
                ? Icon(icon, color: Colors.grey.shade500, size: 20)
                : (prefixText != null
                    ? Padding(
                        padding: const EdgeInsets.only(left: 16, top: 14, bottom: 14),
                        child: Text(prefixText, style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500)),
                      )
                    : null),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kPrimary)),
          ),
        ),
      ],
    );
  }
}

class _BackupRestoreContent extends StatelessWidget {
  const _BackupRestoreContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.cloud_upload_outlined, size: 18),
          label: const Text('Backup Data'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.restore_outlined, size: 18),
          label: const Text('Restore Data'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF333333),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ],
    );
  }
}

class _ChangePasswordContent extends StatelessWidget {
  const _ChangePasswordContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPasswordField(label: 'Current Password', hint: 'Enter current password', obscure: false),
        const SizedBox(height: 20),
        _buildPasswordField(label: 'New Password', hint: 'Enter new password', obscure: true),
        const SizedBox(height: 20),
        _buildPasswordField(label: 'Confirm Password', hint: 'Confirm new password', obscure: true),
      ],
    );
  }

  Widget _buildPasswordField({required String label, required String hint, required bool obscure}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(obscure ? Icons.password_outlined : Icons.lock_outline, color: Colors.grey.shade500, size: 20),
            suffixIcon: Icon(Icons.visibility_outlined, color: Colors.grey.shade500, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kPrimary)),
          ),
        ),
      ],
    );
  }
}
