import sys

with open('lib/screens/billing_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_content = """                        Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header: Product Info & Cancel
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _stagedProduct!.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: Color(0xFF1E293B),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDBEAFE),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Stock: ${_stagedProduct!.formattedStock}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1E40AF),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      color: Colors.grey.shade400,
                                      onPressed: () => setState(
                                          () => _stagedProduct = null),
                                    ),
                                  ],
                                ),
                              ),
                              // Body: Inputs
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  crossAxisAlignment: WrapCrossAlignment.end,
                                  children: [
                                    // Unit Dropdown
                                    if (_stagedProduct!.packaging.isNotEmpty)
                                      SizedBox(
                                        width: 120,
                                        child: DropdownButtonFormField<
                                            String>(
                                          value: _stagedUnit,
                                          isDense: true,
                                          decoration: InputDecoration(
                                            labelText: 'Unit',
                                            labelStyle: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF64748B)),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                  color: Color(0xFFE2E8F0)),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                  color: Color(0xFFE2E8F0)),
                                            ),
                                          ),
                                          items: _stagedProduct!.packaging
                                              .map(
                                                (u) => DropdownMenuItem(
                                                  value: u.name,
                                                  child: Text(
                                                    u.name,
                                                    style: const TextStyle(
                                                        fontSize: 13),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              _stagedUnit = val;
                                              if (_selectedBatch != null) {
                                                final unit = _stagedUnit ??
                                                    (_stagedProduct!.packaging
                                                            .isNotEmpty
                                                        ? _stagedProduct!
                                                            .packaging
                                                            .first
                                                            .name
                                                        : 'Unit');
                                                final reqBase = _stagedQty *
                                                    _stagedProduct!
                                                        .getMultiplier(unit);
                                                final batchQty =
                                                    (_selectedBatch![
                                                                'batch_quantity']
                                                            as num)
                                                        .toDouble();
                                                if (batchQty < reqBase) {
                                                  _selectedBatch = null;
                                                }
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    // Qty
                                    SizedBox(
                                      width: 90,
                                      child: TextFormField(
                                        controller: _qtyController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600),
                                        decoration: InputDecoration(
                                          labelText: 'Qty',
                                          labelStyle: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF64748B)),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: Color(0xFFE2E8F0)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: Color(0xFFE2E8F0)),
                                          ),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            _stagedQty =
                                                int.tryParse(val) ?? 0;
                                            if (_stagedQty <= 0) {
                                              _selectedBatch = null;
                                            } else if (_selectedBatch !=
                                                null) {
                                              final unit = _stagedUnit ??
                                                  (_stagedProduct!.packaging
                                                          .isNotEmpty
                                                      ? _stagedProduct!
                                                          .packaging
                                                          .first
                                                          .name
                                                      : 'Unit');
                                              final reqBase = _stagedQty *
                                                  _stagedProduct!
                                                      .getMultiplier(unit);
                                              final batchQty =
                                                  (_selectedBatch![
                                                              'batch_quantity']
                                                          as num)
                                                      .toDouble();
                                              if (batchQty < reqBase) {
                                                _selectedBatch = null;
                                              }
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    // GST
                                    SizedBox(
                                      width: 90,
                                      child: TextFormField(
                                        controller: _stagedGstController,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                          decimal: true,
                                        ),
                                        style: const TextStyle(fontSize: 14),
                                        decoration: InputDecoration(
                                          labelText: 'GST %',
                                          labelStyle: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF64748B)),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: Color(0xFFE2E8F0)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: Color(0xFFE2E8F0)),
                                          ),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    // Discount
                                    SizedBox(
                                      width: 110,
                                      child: TextFormField(
                                        controller: _stagedDiscountController,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                          decimal: true,
                                        ),
                                        style: const TextStyle(fontSize: 14),
                                        decoration: InputDecoration(
                                          labelText:
                                              'Disc (${_selectedBatch?['discount_type'] == 'Percentage' ? '%' : 'Rs'})',
                                          labelStyle: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF64748B)),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: Color(0xFFE2E8F0)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: Color(0xFFE2E8F0)),
                                          ),
                                        ),
                                        onChanged: (val) {
                                          final entered =
                                              double.tryParse(val) ?? 0.0;
                                          final batchDisc =
                                              (_selectedBatch?['discount']
                                                      as num?)
                                                  ?.toDouble() ??
                                              0.0;
                                          if (entered > batchDisc) {
                                            _stagedDiscountController.text =
                                                batchDisc.toStringAsFixed(2);
                                            _stagedDiscountController
                                                    .selection =
                                                TextSelection.fromPosition(
                                              TextPosition(
                                                offset:
                                                    _stagedDiscountController
                                                        .text
                                                        .length,
                                              ),
                                            );
                                          }
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Batch Selection
                              Builder(
                                builder: (context) {
                                  final unit = _stagedUnit ??
                                      (_stagedProduct!.packaging.isNotEmpty
                                          ? _stagedProduct!.packaging.first.name
                                          : 'Unit');
                                  final reqBase = _stagedQty *
                                      _stagedProduct!.getMultiplier(unit);
                                  final validBatches = _stagedBatches
                                      .where(
                                        (b) =>
                                            (b['batch_quantity'] as num)
                                                .toDouble() >=
                                            reqBase,
                                      )
                                      .toList();
                                  final effectiveSelectedBatchId =
                                      (_selectedBatch != null &&
                                              validBatches.any((b) =>
                                                  b['id'] == _selectedBatch!['id']))
                                          ? _selectedBatch!['id'] as int?
                                          : null;
                                  List<DropdownMenuItem<int?>> items = [];
                                  if (_stagedQty <= 0) {
                                    items.add(
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('Enter valid Qty first', style: TextStyle(color: Colors.grey)),
                                      ),
                                    );
                                  } else if (validBatches.isEmpty) {
                                    items.add(
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('No batches with sufficient stock (Auto FEFO)', style: TextStyle(color: Colors.grey)),
                                      ),
                                    );
                                  } else {
                                    items.add(
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('Auto Select (FEFO)'),
                                      ),
                                    );
                                    items.addAll(
                                      validBatches.map((b) {
                                        final discount = (b['discount'] as num?)?.toDouble() ?? 0.0;
                                        final discountStr = discount > 0 ? ' - Disc: $discount ${b['discount_type']}' : '';
                                        return DropdownMenuItem<int?>(
                                          value: b['id'] as int,
                                          child: Text('Batch #${b['id']} (Stock: ${b['batch_quantity']})$discountStr'),
                                        );
                                      }),
                                    );
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: DropdownButtonFormField<int?>(
                                      value: effectiveSelectedBatchId,
                                      decoration: InputDecoration(
                                        labelText: 'Select Batch / Discount',
                                        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                        ),
                                      ),
                                      items: items,
                                      onChanged: _stagedQty <= 0 || validBatches.isEmpty
                                          ? null
                                          : (val) {
                                              setState(() {
                                                _selectedBatch = val == null
                                                    ? null
                                                    : _stagedBatches.firstWhere((b) => b['id'] == val);
                                              });
                                            },
                                    ),
                                  );
                                },
                              ),
                              if (_stagedError != null)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.red, size: 14),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _stagedError!,
                                          style: const TextStyle(color: Colors.red, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Footer: Totals and Action
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(12),
                                  ),
                                  border: Border(
                                    top: BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Rs. ${_stagedPricePerUnit.toStringAsFixed(0)} / unit',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Total: Rs. ${_stagedLineTotal.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F4C81),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _addStagedToCart,
                                      icon: const Icon(
                                        Icons.add_shopping_cart,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Add to Cart',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1E40AF),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
"""

lines = lines[:2904] + [new_content + "\n"] + lines[3115:]

with open('lib/screens/billing_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)
