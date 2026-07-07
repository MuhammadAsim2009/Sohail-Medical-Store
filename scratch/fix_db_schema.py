import sys
sys.stdout.reconfigure(encoding='utf-8')
lines = open(r'd:\pharmacy\lib\services\database_helper.dart', encoding='utf-8').readlines()

end_supplier_payments = -1
for i, line in enumerate(lines):
    if 'CREATE TABLE IF NOT EXISTS supplier_payments' in line:
        for j in range(i, len(lines)):
            if ')""");' in lines[j]:
                end_supplier_payments = j
                break
        break

new_lines = lines[:end_supplier_payments+1]
new_lines.append('    }\n')
new_lines.append('    if (oldVersion < 14) {\n')
new_lines.append('      // version 14 updates (empty or logic from before)\n')
new_lines.append('    }\n')
new_lines.append('    if (oldVersion < 15) {\n')
new_lines.append('      // Add missing columns to settings table\n')
new_lines.append('      try { await db.execute("ALTER TABLE settings ADD COLUMN sync_id TEXT"); } catch(_) {}\n')
new_lines.append('      try { await db.execute("ALTER TABLE settings ADD COLUMN updated_at INTEGER DEFAULT 0"); } catch(_) {}\n')
new_lines.append('      try { await db.execute("ALTER TABLE settings ADD COLUMN is_dirty INTEGER DEFAULT 0"); } catch(_) {}\n')
new_lines.append('      try { await db.execute("ALTER TABLE settings ADD COLUMN is_deleted INTEGER DEFAULT 0"); } catch(_) {}\n')
new_lines.append('    }\n')
new_lines.append('  }\n\n')
new_lines.append('  // ---------------------------------------------------------------------------\n')

for i, line in enumerate(lines):
    if '// SETTINGS' in line:
        start_settings = i - 1
        new_lines.extend(lines[start_settings:])
        break

open(r'd:\pharmacy\lib\services\database_helper.dart', 'w', encoding='utf-8').write(''.join(new_lines))
print('Fixed database_helper.dart')
