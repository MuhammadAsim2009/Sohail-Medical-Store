import re

with open(r'd:\pharmacy\lib\screens\sales_return_screen.dart', 'rb') as f:
    content = f.read().decode('utf-8')

# Find and remove the stray block between the two closing braces of build()
# The stray block starts at the first closing brace of build() and has dangling brackets
stray = '\r\n              ),\r\n            ],\r\n          ),\r\n        ),\r\n      ],\r\n    );\r\n  }\r\n'
replacement = '\r\n'

if stray in content:
    # Find the position after the second occurrence of '  }\n\n'
    # We need to remove the stray block that appears after the first build() close
    idx = content.find(stray)
    if idx != -1:
        # Find what precedes it - it should be just after '  }\n\n'
        before = content[:idx]
        after = content[idx + len(stray):]
        content = before + replacement + after
        print(f"Removed stray block at position {idx}")
    else:
        print("Stray block not found!")
else:
    print("Stray pattern not found, trying Unix line endings...")
    stray_unix = '\n              ),\n            ],\n          ),\n        ),\n      ],\n    );\n  }\n'
    if stray_unix in content:
        idx = content.find(stray_unix)
        before = content[:idx]
        after = content[idx + len(stray_unix):]
        content = before + '\n' + after
        print(f"Removed stray block (unix) at position {idx}")
    else:
        print("Pattern not found at all. Printing lines 344-356:")
        lines = content.split('\n')
        for i, line in enumerate(lines[343:358], start=344):
            print(f"{i}: {repr(line)}")

with open(r'd:\pharmacy\lib\screens\sales_return_screen.dart', 'wb') as f:
    f.write(content.encode('utf-8'))

print("Done.")
