import 'package:flutter/material.dart';
import '../services/firebase_sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import '../widgets/executive_header.dart';
import '../services/database_helper.dart';
import '../utils/app_feedback.dart';
import 'login_screen.dart';

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
            const ExecutiveHeader(
              title: 'Settings',
              subtitle:
                  'Manage store preferences, user accounts, backup, and sync configuration.',
            ),
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
                      const SizedBox(height: 24),
                      _SettingsCard(
                        title: 'Synchronization',
                        child: const _SyncSettingsContent(),
                      ),
                      const SizedBox(height: 24),
                      _SettingsCard(
                        title: 'Danger Zone',
                        child: const _DangerZoneContent(),
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
          Padding(padding: const EdgeInsets.all(24.0), child: child),
        ],
      ),
    );
  }
}

class _GeneralSettingsContent extends StatefulWidget {
  const _GeneralSettingsContent();

  @override
  State<_GeneralSettingsContent> createState() =>
      _GeneralSettingsContentState();
}

class _GeneralSettingsContentState extends State<_GeneralSettingsContent> {
  final _shopNameController = TextEditingController();
  final _shopOwnerNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _shopPhoneController = TextEditingController();
  final _taxRateController = TextEditingController();
  bool _showTaxInReceipt = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper.instance.getAllSettings();
    setState(() {
      _shopNameController.text = settings['shop_name'] ?? '';
      _shopOwnerNameController.text = settings['shop_owner_name'] ?? '';
      _shopAddressController.text = settings['shop_address'] ?? '';
      _shopPhoneController.text = settings['shop_phone'] ?? '';
      _taxRateController.text = settings['tax_rate'] ?? '0';
      _showTaxInReceipt = (settings['show_tax_in_receipt'] ?? 'true') == 'true';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await DatabaseHelper.instance.setSetting(
      'shop_name',
      _shopNameController.text,
    );
    await DatabaseHelper.instance.setSetting(
      'shop_owner_name',
      _shopOwnerNameController.text,
    );
    await DatabaseHelper.instance.setSetting(
      'shop_address',
      _shopAddressController.text,
    );
    await DatabaseHelper.instance.setSetting(
      'shop_phone',
      _shopPhoneController.text,
    );
    await DatabaseHelper.instance.setSetting(
      'tax_rate',
      _taxRateController.text,
    );
    await DatabaseHelper.instance.setSetting(
      'show_tax_in_receipt',
      _showTaxInReceipt.toString(),
    );

    if (mounted) {
      AppFeedback.show(
        context,
        'Settings saved successfully.',
        type: AppFeedbackType.success,
      );
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopOwnerNameController.dispose();
    _shopAddressController.dispose();
    _shopPhoneController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildField(
          controller: _shopNameController,
          label: 'Shop Name',
          hint: 'e.g. Sohail Medical Store',
          icon: Icons.store_mall_directory_outlined,
        ),
        const SizedBox(height: 20),
        _buildField(
          controller: _shopOwnerNameController,
          label: 'Shop Owner Name',
          hint: 'e.g. Muhammad Sohail',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 20),
        _buildField(
          controller: _shopAddressController,
          label: 'Shop Address',
          hint: 'e.g. Main Market, Larkana',
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 20),
        _buildField(
          controller: _shopPhoneController,
          label: 'Shop Phone',
          hint: '+92 300 1234567',
          icon: Icons.phone_outlined,
        ),
        const SizedBox(height: 20),
        _buildField(
          controller: _taxRateController,
          label: 'Tax Rate',
          hint: '0',
          prefixText: '%   ',
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Show Tax in Receipt',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Display tax amount on printed receipts',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            Switch(
              value: _showTaxInReceipt,
              activeThumbColor: _kPrimary,
              onChanged: (val) => setState(() => _showTaxInReceipt = val),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            prefixIcon: icon != null
                ? Icon(icon, color: Colors.grey.shade500, size: 20)
                : (prefixText != null
                      ? Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            top: 14,
                            bottom: 14,
                          ),
                          child: Text(
                            prefixText,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : null),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackupRestoreContent extends StatelessWidget {
  const _BackupRestoreContent();

  Future<void> _backup(BuildContext context) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'pharmacy.db');
      final file = File(path);

      final downloadsDir = p.join(
        Platform.environment['USERPROFILE'] ?? 'C:\\',
        'Downloads',
      );
      final backupPath = p.join(
        downloadsDir,
        'pharmacy_backup_${DateTime.now().millisecondsSinceEpoch}.db',
      );

      if (await file.exists()) {
        await file.copy(backupPath);
        AppFeedback.show(
          context,
          'Backup saved to: $backupPath',
          type: AppFeedbackType.success,
        );
      } else {
        AppFeedback.show(
          context,
          'Database not found.',
          type: AppFeedbackType.warning,
        );
      }
    } catch (e) {
      AppFeedback.show(context, 'Error: $e', type: AppFeedbackType.error);
    }
  }

  Future<void> _restore(BuildContext context) async {
    String? selectedPath;
    final restored = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Restore Database'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedPath == null
                    ? 'No backup file selected.'
                    : selectedPath!,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    dialogTitle: 'Select backup database',
                    type: FileType.custom,
                    allowedExtensions: ['db', 'sqlite', 'sqlite3'],
                    allowMultiple: false,
                  );
                  final path = result?.files.single.path;
                  if (path != null && path.isNotEmpty) {
                    setDialogState(() => selectedPath = path);
                  }
                },
                icon: const Icon(Icons.folder_open_outlined, size: 18),
                label: const Text('Browse'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedPath == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      ),
    );

    if (restored != true || selectedPath == null) {
      return;
    }

    try {
      final source = File(selectedPath!);
      if (!await source.exists()) {
        AppFeedback.show(
          context,
          'Backup file not found.',
          type: AppFeedbackType.warning,
        );
        return;
      }

      final dbPath = await getDatabasesPath();
      final target = File(p.join(dbPath, 'pharmacy.db'));

      await DatabaseHelper.instance.closeDatabase();
      await source.copy(target.path);
      await DatabaseHelper.instance.database;

      AppFeedback.show(
        context,
        'Database restored successfully. Restart the app if needed.',
        type: AppFeedbackType.success,
      );
    } catch (e) {
      AppFeedback.show(
        context,
        'Restore failed: $e',
        type: AppFeedbackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _backup(context),
          icon: const Icon(Icons.cloud_upload_outlined, size: 18),
          label: const Text('Backup Data'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _restore(context),
          icon: const Icon(Icons.restore_outlined, size: 18),
          label: const Text('Restore Data'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF333333),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ],
    );
  }
}

class _ChangePasswordContent extends StatefulWidget {
  const _ChangePasswordContent();

  @override
  State<_ChangePasswordContent> createState() => _ChangePasswordContentState();
}

class _ChangePasswordContentState extends State<_ChangePasswordContent> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _changePassword() async {
    print("DEBUG: Update button pressed.");
    final currentInput = _currentController.text;
    final newPass = _newController.text;
    final confirmPass = _confirmController.text;

    if (newPass.isEmpty || confirmPass.isEmpty || currentInput.isEmpty) {
      print("DEBUG: Validation failed - Empty fields.");
      AppFeedback.show(
        context,
        'Please fill all fields.',
        type: AppFeedbackType.warning,
      );
      return;
    }

    if (newPass != confirmPass) {
      print("DEBUG: Validation failed - Passwords do not match.");
      AppFeedback.show(
        context,
        'New passwords do not match.',
        type: AppFeedbackType.warning,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Starting...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        print("DEBUG: Attempting re-authentication for ${user.email}.");
        setState(() => _statusMessage = 'Re-authenticating with Firebase...');

        // Use signInWithEmailAndPassword instead of reauthenticateWithCredential
        // because reauthenticateWithCredential is known to hang indefinitely on Flutter Windows desktop.
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: user.email!,
              password: currentInput,
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () =>
                  throw TimeoutException("Re-authentication timed out"),
            );

        print(
          "DEBUG: Re-authentication successful. Attempting to update password.",
        );
        setState(() => _statusMessage = 'Updating Firebase password...');

        await user
            .updatePassword(newPass)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () =>
                  throw TimeoutException("Update password timed out"),
            );

        print("DEBUG: Firebase password updated.");

        print("DEBUG: Process completed successfully.");
        if (mounted) {
          AppFeedback.show(
            context,
            'Password changed successfully.',
            type: AppFeedbackType.success,
          );
          _currentController.clear();
          _newController.clear();
          _confirmController.clear();
        }
      } else {
        print("DEBUG: No active user session found (user or email is null).");
        if (mounted)
          AppFeedback.show(
            context,
            'No active user session found.',
            type: AppFeedbackType.error,
          );
      }
    } on FirebaseAuthException catch (e) {
      print("DEBUG: FirebaseAuthException caught: ${e.code} - ${e.message}");
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        if (mounted)
          AppFeedback.show(
            context,
            'Current password is incorrect.',
            type: AppFeedbackType.error,
          );
      } else {
        if (mounted)
          AppFeedback.show(
            context,
            'Error: ${e.message}',
            type: AppFeedbackType.error,
          );
      }
    } catch (e) {
      print("DEBUG: General Exception caught: $e");
      if (mounted)
        AppFeedback.show(
          context,
          'Failed to update password: $e',
          type: AppFeedbackType.error,
        );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPasswordField(
          controller: _currentController,
          label: 'Current Password',
          hint: 'Enter current password',
          obscure: _obscureCurrent,
          onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          controller: _newController,
          label: 'New Password',
          hint: 'Enter new password',
          obscure: _obscureNew,
          onToggle: () => setState(() => _obscureNew = !_obscureNew),
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          controller: _confirmController,
          label: 'Confirm Password',
          hint: 'Confirm new password',
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _changePassword,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.lock_reset, size: 18),
            label: Text(_isLoading ? 'Updating...' : 'Update Password'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _kPrimary.withValues(alpha: 0.6),
              disabledForegroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
        if (_isLoading && _statusMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                _statusMessage,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Colors.grey.shade500,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade500,
                size: 20,
              ),
              onPressed: onToggle,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

class _SyncSettingsContent extends StatefulWidget {
  const _SyncSettingsContent();

  @override
  State<_SyncSettingsContent> createState() => _SyncSettingsContentState();
}

class _SyncSettingsContentState extends State<_SyncSettingsContent> {
  bool _isSyncing = false;

  Future<void> _runSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    try {
      final result = await FirebaseSyncService.instance.sync();

      if (!mounted) return;

      if (result.offline) {
        AppFeedback.show(
          context,
          'Sync failed: No internet connection or route to Google',
          type: AppFeedbackType.error,
        );
      } else if (result.notAuthenticated) {
        AppFeedback.show(
          context,
          'Sync failed: Not authenticated with Firebase',
          type: AppFeedbackType.error,
        );
      } else {
        final hasErrors = result.errors.isNotEmpty;
        final type = hasErrors
            ? AppFeedbackType.warning
            : AppFeedbackType.success;
        AppFeedback.show(
          context,
          'Synced: ${result.pushed} pushed, ${result.pulled} pulled.${hasErrors ? ' Some tables had errors.' : ''}',
          type: type,
        );
      }
    } catch (e) {
      if (mounted)
        AppFeedback.show(
          context,
          'Sync Error: $e',
          type: AppFeedbackType.error,
        );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manually synchronize your local database with Firebase Firestore. '
          'The system uses a richness-based two-way sync.',
          style: TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.5),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _isSyncing ? null : _runSync,
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.sync, size: 18),
            label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F6E5C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// DANGER ZONE
// ---------------------------------------------------------------------------
class _DangerZoneContent extends StatefulWidget {
  const _DangerZoneContent();

  @override
  State<_DangerZoneContent> createState() => _DangerZoneContentState();
}

class _DangerZoneContentState extends State<_DangerZoneContent> {
  bool _isWiping = false;

  Future<void> _handleWipeData() async {
    final confirmCtrl = TextEditingController();
    bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete All Data',
            style: TextStyle(color: Colors.red),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will permanently delete all records locally and on the cloud. '
                'This action cannot be undone. To proceed, please type "DELETE" below.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Type DELETE',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (confirmCtrl.text.trim() == 'DELETE') {
                  Navigator.of(context).pop(true);
                } else {
                  AppFeedback.show(
                    context,
                    'You must type DELETE to confirm.',
                    type: AppFeedbackType.error,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Wipe Data'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isWiping = true);

      try {
        await FirebaseSyncService.instance.wipeAllData();

        if (!mounted) return;
        AppFeedback.show(
          context,
          'All data deleted successfully.',
          type: AppFeedbackType.success,
        );

        // Restart the app / Go to Login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        if (mounted) {
          AppFeedback.show(
            context,
            'Error wiping data: $e',
            type: AppFeedbackType.error,
          );
        }
      } finally {
        if (mounted) setState(() => _isWiping = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Wipe all data from the device and the cloud. This will completely reset the database.',
          style: TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.5),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _isWiping ? null : _handleWipeData,
            icon: _isWiping
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.delete_forever, size: 18),
            label: Text(_isWiping ? 'Wiping Data...' : 'Delete All Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}
