path = r'd:\pharmacy\lib\screens\purchase_orders_screen.dart'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old = 'builder: (context, setSearchState) {\n                                  final q = _itemSearchCtrl.text.trim().toLowerCase();\n                                  final filtered = _items.asMap().entries.where((e) {\n                                    if (q.isEmpty) return true;\n                                    return e.value.product.name.toLowerCase().contains(q) ||\n                                        e.value.product.sku.toLowerCase().contains(q);\n                                  }).toList();\n\n                                  return Column('

new = 'builder: (context, setSearchState) {\n                                  final q = _itemSearchCtrl.text.trim().toLowerCase();\n                                  List<MapEntry<int, _ItemRow>> displayed;\n                                  if (q.isEmpty) {\n                                    displayed = _items.asMap().entries.toList().reversed.toList();\n                                  } else {\n                                    final all = _items.asMap().entries.where((e) {\n                                      final name = e.value.product.name.toLowerCase();\n                                      final sku = e.value.product.sku.toLowerCase();\n                                      return name.contains(q) || sku.contains(q);\n                                    }).toList();\n                                    all.sort((a, b) {\n                                      final aScore = a.value.product.name.toLowerCase().startsWith(q) ? 0 : 1;\n                                      final bScore = b.value.product.name.toLowerCase().startsWith(q) ? 0 : 1;\n                                      return aScore.compareTo(bScore);\n                                    });\n                                    displayed = all;\n                                  }\n\n                                  return Column('

if old in content:
    content = content.replace(old, new, 1)
    # Also replace the rendering variable name
    content = content.replace(
        ': displayed.isEmpty',
        ': displayed.isEmpty',
        1
    )
    content = content.replace(
        'children: displayed.map((e) {',
        'children: displayed.map((e) {',
        1
    )
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("SUCCESS: replaced filtered with displayed")
else:
    print("ERROR: still not found")
    print(repr(old[:100]))
