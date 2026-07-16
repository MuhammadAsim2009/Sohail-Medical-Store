import 'dart:convert';

class ProductUnit {
  String name;
  int contains; // Number of the NEXT SMALLER unit this unit holds. 1 if it's the base unit.

  ProductUnit({required this.name, required this.contains});

  Map<String, dynamic> toMap() => {
    'name': name,
    'contains': contains,
  };

  factory ProductUnit.fromMap(Map<String, dynamic> map) {
    return ProductUnit(
      name: map['name'],
      contains: map['contains'] ?? 1,
    );
  }
}

class Product {
  int? id;
  String sku;
  String name;
  String category;
  double costPrice;
  double sellPrice;
  double stock;       // Stored as total base units
  double threshold;
  double gst;
  List<ProductUnit> packaging;

  Product({
    this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.costPrice,
    required this.sellPrice,
    required this.stock,
    required this.threshold,
    this.gst = 0.0,
    required this.packaging,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sku': sku,
      'name': name,
      'category': category,
      'cost_price': costPrice,
      'sell_price': sellPrice,
      'stock': stock,
      'threshold': threshold,
      'gst': gst,
      'packaging': jsonEncode(packaging.map((e) => e.toMap()).toList()),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    List<ProductUnit> pkg = [];
    if (map['packaging'] != null) {
      try {
        var decoded = jsonDecode(map['packaging']) as List? ?? [];
        pkg = decoded.map((e) => ProductUnit.fromMap(e as Map<String, dynamic>)).toList();
      } catch (e) {
        // fallback
      }
    }
    return Product(
      id: map['id'] as int?,
      sku: map['sku'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      costPrice: (map['cost_price'] as num).toDouble(),
      sellPrice: (map['sell_price'] as num).toDouble(),
      stock: (map['stock'] as num).toDouble(),
      threshold: (map['threshold'] as num).toDouble(),
      gst: (map['gst'] as num?)?.toDouble() ?? 0.0,
      packaging: pkg,
    );
  }

  /// Calculates the multiplier to convert this unit into the Base Unit.
  /// Example: [Box(3), Strip(10), Tablet(1)]
  /// getMultiplier('Box') -> 3 * 10 * 1 = 30
  /// getMultiplier('Strip') -> 10 * 1 = 10
  /// getMultiplier('Tablet') -> 1
  int getMultiplier(String unitName) {
    int index = packaging.indexWhere((u) => u.name == unitName);
    if (index == -1) return 1;

    int multiplier = 1;
    for (int i = index; i < packaging.length; i++) {
      multiplier *= packaging[i].contains;
    }
    return multiplier;
  }

  String get status {
    if (stock <= 0) return 'Out of Stock';
    if (stock <= threshold) return 'Low Stock';
    return 'Healthy';
  }

  double get inventoryValue => costPrice * stock;

  String get formattedStock {
    if (packaging.isEmpty) return '${stock.toInt()} Units';
    double remaining = stock;
    List<String> parts = [];
    
    for (var u in packaging) {
      int mult = getMultiplier(u.name);
      int qty = (remaining / mult).floor();
      if (qty > 0) {
        parts.add('$qty ${u.name}');
        remaining -= qty * mult;
      }
    }
    
    if (parts.isEmpty && packaging.isNotEmpty) {
      return '0 ${packaging.last.name}';
    }
    return parts.join(', ');
  }

  String get formattedPackaging {
    if (packaging.isEmpty) return 'None';
    if (packaging.length == 1) return packaging.first.name;
    
    List<String> parts = [];
    for (int i = 0; i < packaging.length - 1; i++) {
      parts.add('1 ${packaging[i].name} = ${packaging[i].contains} ${packaging[i+1].name}');
    }
    return parts.join(' | ');
  }
}
