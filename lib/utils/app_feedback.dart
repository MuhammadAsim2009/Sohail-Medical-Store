import 'package:flutter/material.dart';

enum AppFeedbackType { success, error, warning }

class AppFeedback {
  static void show(
    BuildContext context,
    String message, {
    AppFeedbackType type = AppFeedbackType.success,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    const snackBarWidth = 420.0;
    final leftMargin = screenWidth > snackBarWidth + 48 ? screenWidth - snackBarWidth - 24 : 24.0;
    final colors = switch (type) {
      AppFeedbackType.success => (background: const Color(0xFF2E7D32), icon: Icons.check_circle_rounded),
      AppFeedbackType.error => (background: const Color(0xFFC62828), icon: Icons.error_outline_rounded),
      AppFeedbackType.warning => (background: const Color(0xFFEF6C00), icon: Icons.warning_amber_rounded),
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.background,
          margin: EdgeInsets.only(bottom: 24, right: 24, left: leftMargin),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(colors.icon, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
