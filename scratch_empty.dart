  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.bar_chart_rounded, color: _kPrimary, size: 36),
            ),
            const SizedBox(height: 24),
            const Text('Select report type', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2B))),
            const SizedBox(height: 10),
            Text(
              'Choose a report type from the left column to start generating a\nfocused business report on screen.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
