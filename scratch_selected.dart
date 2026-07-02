  Widget _buildSelectedState() {
    final report = _reportTypes[_selectedIndex!];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A2E2B))),
                  const SizedBox(height: 8),
                  Text(report.description, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(width: 24),
            ElevatedButton.icon(
              onPressed: _generateReport,
              icon: _isGenerating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.flash_on_rounded, size: 20),
              label: Text(_isGenerating ? 'Generating...' : 'Generate Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Sub Filters (Segmented Control equivalent)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(report.subFilters.length, (index) {
              final isSelected = _selectedSubFilterIndex == index;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSubFilterIndex = index;
                      _reportData = null; // Clear data when switching
                    });
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? _kPrimary.withValues(alpha: 0.1) : Colors.white,
                      border: Border.all(color: isSelected ? _kPrimary : Colors.grey.shade300, width: 1.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      report.subFilters[index],
                      style: TextStyle(
                        color: isSelected ? _kPrimary : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 24),

        // Search and Date Filter
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search \...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (val) {
                    if (_reportData != null) {
                      // We would trigger a local filter here if needed, 
                      // or just clear data to force re-generation
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: PopupMenuButton<String>(
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) => setState(() { _selectedRange = val; _reportData = null; }),
                itemBuilder: (context) => ['Today', 'Yesterday', 'This Week', 'This Month', 'Last Month', 'This Year']
                    .map((r) => PopupMenuItem(value: r, child: Text(r))).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedRange,
                          style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1A2E2B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Main Report Area
        Expanded(
          child: _reportData == null 
            ? _buildPreviewPlaceholder(report.label)
            : _buildGeneratedReport(report.id),
        ),
      ],
    );
  }

  Widget _buildPreviewPlaceholder(String reportLabel) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: const Icon(Icons.description_outlined, size: 48, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text('Generate a \ snapshot', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A2E2B))),
            const SizedBox(height: 12),
            Text(
              'Use the mode and search above to review data\\nand generate focused business insights.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
