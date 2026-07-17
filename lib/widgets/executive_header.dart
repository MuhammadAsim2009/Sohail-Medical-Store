import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/firebase_sync_service.dart';
import '../services/database_helper.dart';
import '../utils/app_feedback.dart';

class ExecutiveHeader extends StatefulWidget {
  final String title;
  final String subtitle;

  const ExecutiveHeader({
    super.key,
    this.title = 'Executive Dashboard',
    this.subtitle = 'Monitor sales momentum, outstanding balances, stock posture, and daily activity\nfrom one finance-grade workspace.',
  });

  @override
  State<ExecutiveHeader> createState() => _ExecutiveHeaderState();
}

class _ExecutiveHeaderState extends State<ExecutiveHeader> {
  bool _isSyncing = false;
  bool _isPending = false;
  DateTime? _lastSyncTime;
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadLastSyncTime();
    _checkInitialConnectivity();
    
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      bool hasConnection = !results.contains(ConnectivityResult.none);
      if (hasConnection && _isPending) {
        _syncNow();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.none)) {
      if (mounted) setState(() => _isPending = true);
    }
  }

  Future<void> _loadLastSyncTime() async {
    final raw = await DatabaseHelper.instance.getSetting('last_sync_timestamp');
    if (raw != null) {
      final ts = int.tryParse(raw);
      if (ts != null && ts > 0) {
        if (mounted) {
          setState(() {
            _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(ts);
          });
        }
      }
    }
  }

  Future<void> _syncNow() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
      _isPending = false;
    });

    try {
      // Only force full richness sync on first-ever sync (timestamp == 0)
      final lastSyncRaw = await DatabaseHelper.instance.getSetting('last_sync_timestamp');
      final lastSyncTs = int.tryParse(lastSyncRaw ?? '0') ?? 0;
      final isFirstSync = lastSyncTs == 0;

      final result = await FirebaseSyncService.instance
          .sync(forceInitial: isFirstSync, forceReset: true);

      if (!mounted) return;

      if (result.busy) {
        AppFeedback.show(context, 'Sync already in progress. Please wait.', type: AppFeedbackType.warning);
      } else if (result.offline) {
        AppFeedback.show(context, 'Sync failed: No internet connection or route to Google', type: AppFeedbackType.error);
        setState(() => _isPending = true);
      } else if (result.notAuthenticated) {
        AppFeedback.show(context, 'Sync failed: Not authenticated with Firebase', type: AppFeedbackType.error);
        setState(() => _isPending = true);
      } else {
        final hasErrors = result.errors.isNotEmpty;
        final errorDetail = hasErrors ? '\nErrors: ${result.errors.take(3).join('; ')}' : '';
        AppFeedback.show(
          context,
          'Synced: ${result.pushed} pushed, ${result.pulled} pulled.$errorDetail',
          type: hasErrors ? AppFeedbackType.warning : AppFeedbackType.success,
        );
        await _loadLastSyncTime();
      }
    } catch (e) {
      debugPrint('Sync failed or timed out: $e');
      if (mounted) {
        AppFeedback.show(context, 'Sync Error: $e', type: AppFeedbackType.error);
        setState(() => _isPending = true);
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEE, d MMM yyyy').format(DateTime.now());
    
    String syncText = 'Pending';
    String syncSubText = 'Not synced yet';
    Color syncColor = Colors.orange.shade600;
    Color syncBgColor = Colors.orange.shade50;
    IconData syncIcon = Icons.cloud_off_outlined;

    if (_isSyncing) {
      syncText = 'Syncing...';
      syncSubText = 'Please wait';
      syncColor = Colors.blue.shade600;
      syncBgColor = Colors.blue.shade50;
      syncIcon = Icons.cloud_sync_outlined;
    } else if (_isPending) {
      syncText = 'Pending';
      syncSubText = 'Waiting for connection';
      syncColor = Colors.orange.shade600;
      syncBgColor = Colors.orange.shade50;
      syncIcon = Icons.cloud_off_outlined;
    } else if (_lastSyncTime != null) {
      syncText = 'Data synced';
      syncSubText = 'Updated ${DateFormat('h:mm a').format(_lastSyncTime!)}';
      syncColor = Colors.green.shade600;
      syncBgColor = Colors.green.shade50;
      syncIcon = Icons.cloud_done_outlined;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left side text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2E2B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        
        // Right side buttons
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Reporting Date Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey.shade500),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reporting date', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(today, style: const TextStyle(fontSize: 13, color: Color(0xFF1A2E2B), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // Sync Status Box (Icon Card)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: syncBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: _isSyncing 
                        ? SizedBox(
                            width: 16, 
                            height: 16, 
                            child: CircularProgressIndicator(strokeWidth: 2, color: syncColor)
                          )
                        : Icon(syncIcon, size: 16, color: syncColor),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Firebase sync', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                      Text(syncText, style: const TextStyle(fontSize: 13, color: Color(0xFF1A2E2B), fontWeight: FontWeight.w600)),
                      Text(syncSubText, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // Sync Now Button
            InkWell(
              onTap: _isSyncing ? null : _syncNow,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sync, size: 18, color: _isSyncing ? Colors.grey.shade400 : Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Text('Sync now', style: TextStyle(fontSize: 13, color: _isSyncing ? Colors.grey.shade400 : const Color(0xFF1A2E2B), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
