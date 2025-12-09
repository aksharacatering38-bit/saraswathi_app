import 'menu_item.dart';

class CartItemEntry {
  final MenuItemModel item;
  int quantity;

  CartItemEntry({
    required this.item,
    this.quantity = 1,
  });

  int get totalPrice => item.price * quantity;
}	

