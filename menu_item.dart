import 'package:flutter/foundation.dart';

class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final int price;
  final String category;
  final String itemType;
  final bool isAvailable;
  final String imageUrl;        // <-- FIXED: no '?'
  final bool isBestSeller;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.itemType,
    required this.isAvailable,
    required this.imageUrl,     // <-- FIXED
    required this.isBestSeller,
  });

  factory MenuItemModel.fromMap(Map<String, dynamic> map) {
    return MenuItemModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      category: map['category'] as String? ?? '',
      itemType: map['item_type'] as String? ?? '',
      isAvailable: map['is_available'] as bool? ?? true,
      imageUrl: map['image_url'] as String? ?? '',   // <-- FIXED
      isBestSeller: map['is_best_seller'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'item_type': itemType,
      'is_available': isAvailable,
      'image_url': imageUrl,
      'is_best_seller': isBestSeller,
    };
  }

  @override
  String toString() => 'MenuItem($name, ₹$price)';
}
