import re

file_path = 'd:/pharmacy/lib/screens/purchase_orders_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update _ItemRow
content = content.replace(
    'double discount;',
    'String discountType;\n  double discount;'
)
content = content.replace(
    'this.discount = 0.0,',
    'this.discountType = \'Rupee\',\n    this.discount = 0.0,'
)

# 2. Update _subtotal logic
old_subtotal_1 = """  double get _subtotal {
    double sum = 0;
    for (var r in _rows) {
      final lineSub = r.quantity * r.purchasePrice * (1 + (r.gst / 100));
      sum += (lineSub - r.discount);
    }
    return sum;
  }"""
old_subtotal_2 = """  double get _subtotal {
    double sum = 0;
    for (var r in _rows) {
      sum += r.quantity * r.purchasePrice * (1 + (r.gst / 100)) - r.discount;
    }
    return sum;
  }"""
new_subtotal = """  double get _subtotal {
    double sum = 0;
    for (var r in _rows) {
      final base = r.quantity * r.purchasePrice * (1 + (r.gst / 100));
      final disc = r.discountType == 'Percentage' ? base * (r.discount / 100) : r.discount;
      sum += base - disc;
    }
    return sum;
  }"""
content = content.replace(old_subtotal_1, new_subtotal)
content = content.replace(old_subtotal_2, new_subtotal)
if 'sum += r.quantity * r.purchasePrice * (1 + (r.gst / 100)) - r.discount;' in content:
    content = content.replace('sum += r.quantity * r.purchasePrice * (1 + (r.gst / 100)) - r.discount;',
      'final base = r.quantity * r.purchasePrice * (1 + (r.gst / 100));\n      final disc = r.discountType == \'Percentage\' ? base * (r.discount / 100) : r.discount;\n      sum += base - disc;')
if 'sum += (lineSub - r.discount);' in content:
    content = content.replace('sum += (lineSub - r.discount);',
      'final disc = r.discountType == \'Percentage\' ? lineSub * (r.discount / 100) : r.discount;\n      sum += lineSub - disc;')


# 3. Update _ItemCard UI
old_gst_input = """                            r.gst = double.tryParse(v) ?? 0;
                            widget.onChanged();
                          },
                        ),
                      ),
                    ),
                  ],
                ),"""
new_gst_and_discount = """                            r.gst = double.tryParse(v) ?? 0;
                            widget.onChanged();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _LabelField(
                        label: 'Discount',
                        child: TextFormField(
                          initialValue: r.discount == 0 ? '' : r.discount.toStringAsFixed(2).replaceAll(RegExp(r'([.]*0+)(?!.*\\d)'), ''),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                            hintText: '0',
                          ),
                          onChanged: (v) {
                            r.discount = double.tryParse(v) ?? 0;
                            widget.onChanged();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: _LabelField(
                        label: 'Type',
                        child: Row(
                          children: [
                            Radio<String>(
                              value: 'Percentage',
                              groupValue: r.discountType,
                              onChanged: (v) {
                                if (v != null) {
                                  r.discountType = v;
                                  widget.onChanged();
                                }
                              },
                            ),
                            const Text('%', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 10),
                            Radio<String>(
                              value: 'Rupee',
                              groupValue: r.discountType,
                              onChanged: (v) {
                                if (v != null) {
                                  r.discountType = v;
                                  widget.onChanged();
                                }
                              },
                            ),
                            const Text('Rs.', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),"""
content = content.replace(old_gst_input, new_gst_and_discount)

# 4. Update _OrderFormDialogState
content = content.replace(
    "final TextEditingController _discountCtrl = TextEditingController(text: '0');",
    "final TextEditingController _discountCtrl = TextEditingController(text: '0');\n  String _invoiceDiscType = 'Rupee';"
)

old_inv_discount = """  double get _invoiceDiscount {
    return double.tryParse(_discountCtrl.text) ?? 0.0;
  }"""
new_inv_discount = """  double get _invoiceDiscount {
    final val = double.tryParse(_discountCtrl.text) ?? 0.0;
    if (_invoiceDiscType == 'Percentage') {
      return _subtotal * (val / 100);
    }
    return val;
  }"""
content = content.replace(old_inv_discount, new_inv_discount)

old_disc_summary = """                          _SummaryField(
                            label: 'Discount (Rs.)',
                            controller: _discountCtrl,
                            onChanged: (_) => setState(() {}),
                          ),"""
new_disc_summary = """                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _SummaryField(
                                  label: 'Discount',
                                  controller: _discountCtrl,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Radio<String>(
                                      value: 'Percentage',
                                      groupValue: _invoiceDiscType,
                                      onChanged: (v) {
                                        if (v != null) setState(() => _invoiceDiscType = v);
                                      },
                                    ),
                                    const Text('%'),
                                    Radio<String>(
                                      value: 'Rupee',
                                      groupValue: _invoiceDiscType,
                                      onChanged: (v) {
                                        if (v != null) setState(() => _invoiceDiscType = v);
                                      },
                                    ),
                                    const Text('Rs.'),
                                  ],
                                ),
                              ),
                            ],
                          ),"""
content = content.replace(old_disc_summary, new_disc_summary)

# Update _save()
content = content.replace(
    'discount: r.discount,',
    'discount: r.discount,\n        discountType: r.discountType,'
)
content = content.replace(
    'discount: _invoiceDiscount,',
    'discount: double.tryParse(_discountCtrl.text) ?? 0.0,\n      discountType: _invoiceDiscType,'
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated purchase_orders_screen.dart")
