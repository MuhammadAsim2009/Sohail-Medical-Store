import sys
sys.stdout.reconfigure(encoding='utf-8')
rep_path = r'd:\pharmacy\lib\screens\billing_screen.dart'
rep = open(rep_path, encoding='utf-8').read()
rep = rep.replace("\\'", "'")
open(rep_path, 'w', encoding='utf-8').write(rep)
print('Fixed backslashes in billing_screen.dart')
