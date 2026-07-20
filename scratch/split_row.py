import os

ui_path = r"lib\screens\purchase_orders_screen.dart"
with open(ui_path, 'r', encoding='utf-8') as f:
    content = f.read()

# I want to split the row just before the "// Discount" comment
split_marker_start = '''                    const SizedBox(width: 10),
                    // Discount
                    Expanded('''

replacement = '''                  ],
                ),
                const SizedBox(height: 10),
                // Row 3: Discount + Expiry
                Row(
                  children: [
                    // Discount
                    Expanded('''

if split_marker_start in content:
    content = content.replace(split_marker_start, replacement)
else:
    print("Could not find the split marker for Discount!")

# Now we need to move "Final Sell Price" back to the first row, or let's keep it where it is?
# The user said: "add discount and discount type and expiry date range in new row"
# If I just split at Discount, the new row will have: Discount, Discount Type, Final Sell Price, Expiry Date.
# I will move Final Sell Price to Row 2 by splitting AFTER GST % and moving Final Sell Price before it splits?
# Wait, let's reorganize the widgets.

# Let's define the blocks of code.
# Block 1: GST
# Block 2: Discount
# Block 3: Discount Type
# Block 4: Final Sell Price
# Block 5: Expiry Date

# Since it's easier to manually construct the replacement string by reading the file and regex or just literal replace.

old_middle = '''                    const SizedBox(width: 10),
                    // Discount
                    Expanded(
                      child: _LabelField(
                        label: 'Discount',
                        child: TextFormField(
                          controller: _discountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            r.discount = double.tryParse(v) ?? 0;
                            widget.onChanged();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Discount Type
                    Expanded(
                      child: _LabelField(
                        label: 'Type',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade400),
                            color: Colors.white,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: r.discountType,
                              isExpanded: true,
                              items: ['Rupee', 'Percentage'].map((t) {
                                return DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14)));
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => r.discountType = v);
                                  widget.onChanged();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Show the GST-inclusive preview
                    Expanded(
                      child: _LabelField(
                        label: 'Final Sell Price',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            (r.sellingPrice * (1 + r.gst / 100))
                                .toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F4C81),
                            ),
                          ),
                        ),
                      ),
                    ),'''

new_middle = '''                    const SizedBox(width: 10),
                    // Show the GST-inclusive preview
                    Expanded(
                      child: _LabelField(
                        label: 'Final Sell Price',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            (r.sellingPrice * (1 + r.gst / 100))
                                .toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F4C81),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Row 3: Discount, Discount Type, Expiry Date
                Row(
                  children: [
                    // Discount
                    Expanded(
                      child: _LabelField(
                        label: 'Discount',
                        child: TextFormField(
                          controller: _discountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            r.discount = double.tryParse(v) ?? 0;
                            widget.onChanged();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Discount Type
                    Expanded(
                      child: _LabelField(
                        label: 'Type',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade400),
                            color: Colors.white,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: r.discountType,
                              isExpanded: true,
                              items: ['Rupee', 'Percentage'].map((t) {
                                return DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14)));
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => r.discountType = v);
                                  widget.onChanged();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),'''

content = content.replace(old_middle, new_middle)

with open(ui_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
