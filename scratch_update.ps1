$content = Get-Content 'd:\pharmacy\lib\screens\reports_screen.dart' -Raw
$newFields = "  int? _selectedIndex;
  int _selectedSubFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _selectedRange = 'This Month';
  bool _isGenerating = false;
  Map<String, dynamic>? _reportData;"

$content = $content -replace '(?s)  int\? _selectedIndex;.*?Map<String, dynamic>\? _reportData;', $newFields

$newSidebarTap = "                    onTap: () => setState(() {
                      _selectedIndex = i;
                      _selectedSubFilterIndex = 0;
                      _searchController.clear();
                      _reportData = null;
                    }),"

$content = $content -replace '(?s)                    onTap: \(\) => setState\(\) \{.*?\}\),', $newSidebarTap

Set-Content -Path 'd:\pharmacy\lib\screens\reports_screen.dart' -Value $content
