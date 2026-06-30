import 'package:flutter/material.dart';
import 'package:pharmacy/models/customer.dart';
import 'package:pharmacy/models/product.dart';
import 'package:pharmacy/models/sale.dart';
import 'package:pharmacy/services/database_helper.dart';

// Just for reference, copy paste to billing_screen.dart later
class _NewSaleDialog extends StatefulWidget {
  final int dssId;
  final VoidCallback onSaleAdded;

  const _NewSaleDialog({required this.dssId, required this.onSaleAdded});

  @override
  State<_NewSaleDialog> createState() => _NewSaleDialogState();
}

class _NewSaleDialogState extends State<_NewSaleDialog> {
  static const Color _primary = Color(0xFF0F4C81);

  final List<_CartItem> _cart = [];
  Customer? _selectedCustomer;
  String _paymentMethod = 'Cash';
  
  List<Customer> _customers = [];
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _receivedController = TextEditingController();

  double get _total => _cart.fold(0, (s, i) => s + i.total);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final customers = await DatabaseHelper.instance.getCustomers();
    final products = await DatabaseHelper.instance.getAllProducts();
    if (mounted) {
      setState(() {
        _customers = customers;
        _products = products;
        _isLoading = false;
      });
    }
  }

  void _saveSale() async {
    if (_cart.isEmpty) return;
    
    double received = double.tryParse(_receivedController.text) ?? 0.0;
    if (_paymentMethod == 'Cash' && received < _total && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot have pending balance for walk-in customer')));
      return;
    }

    if (_paymentMethod != 'Cash') {
      received = _total; // Assuming non-cash is full payment via bank/card etc.
    }

    double balance = _total - received;

    setState(() => _isSaving = true);
    
    try {
      final sale = Sale(
        invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
        dssId: widget.dssId,
        customerId: _selectedCustomer?.id,
        customerName: _selectedCustomer?.name,
        date: DateTime.now().toIso8601String(),
        total: _total,
        received: received,
        balance: balance,
        paymentMethod: _paymentMethod,
        status: balance > 0 ? 'Partial' : 'Paid',
      );

      final items = _cart.map((c) => SaleItem(
        productId: c.product.id!,
        productName: c.product.name,
        quantity: c.qty,
        price: c.price,
        total: c.total,
      )).toList();

      await DatabaseHelper.instance.insertSale(sale, items);
      
      if (mounted) {
        widget.onSaleAdded();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(
        child: SizedBox(
          width: 700, height: 580,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 800,
        height: 650,
        child: Column(
          children: [
            // Dialog header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  const Text('New Sale', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A2E2B))),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.grey.shade500,
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Customer + Payment Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<Customer?>(
                            decoration: InputDecoration(
                              labelText: 'Customer',
                              prefixIcon: Icon(Icons.person_outline, size: 17, color: Colors.grey.shade400),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide.none),
                            ),
                            value: _selectedCustomer,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Walk-in Customer')),
                              ..._customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))),
                            ],
                            onChanged: (val) => setState(() => _selectedCustomer = val),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Payment Method',
                              prefixIcon: Icon(Icons.payment_outlined, size: 17, color: Colors.grey.shade400),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide.none),
                            ),
                            value: _paymentMethod,
                            items: ['Cash', 'Card', 'Bank Transfer', 'Other'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                            onChanged: (val) => setState(() => _paymentMethod = val!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _receivedController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Amount Received (Rs)',
                              prefixIcon: Icon(Icons.money, size: 17, color: Colors.grey.shade400),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Medicine search (Autocomplete)
                    Autocomplete<Product>(
                      displayStringForOption: (option) => option.name,
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<Product>.empty();
                        }
                        return _products.where((p) => p.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (Product selection) {
                        setState(() {
                          int index = _cart.indexWhere((c) => c.product.id == selection.id);
                          if (index >= 0) {
                            _cart[index].qty++;
                          } else {
                            _cart.add(_CartItem(product: selection, price: selection.sellPrice, qty: 1));
                          }
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Add Medicine',
                            hintText: 'Search by name...',
                            prefixIcon: Icon(Icons.medication_outlined, size: 17, color: Colors.grey.shade400),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide.none),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Cart
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _cart.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_cart_outlined, size: 40, color: Colors.grey.shade300),
                                    const SizedBox(height: 10),
                                    Text('No items added yet', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: _cart.length,
                                itemBuilder: (_, i) => ListTile(
                                  title: Text(_cart[i].product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                  subtitle: Text('Rs. ${_cart[i].price.toStringAsFixed(0)} × ${_cart[i].qty}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Rs. ${_cart[i].total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, color: _primary)),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            if (_cart[i].qty > 1) {
                                              _cart[i].qty--;
                                            } else {
                                              _cart.removeAt(i);
                                            }
                                          });
                                        },
                                      )
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  const Spacer(),
                  Text('Total: ', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                  Text('Rs. ${_total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _primary)),
                  const SizedBox(width: 20),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                    child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _cart.isEmpty || _isSaving ? null : _saveSale,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                    child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save & Print', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItem {
  final Product product;
  final double price;
  int qty;

  _CartItem({required this.product, required this.price, required this.qty});

  double get total => price * qty;
}
