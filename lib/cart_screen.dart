import 'package:flutter/material.dart';
import 'models/cart_item_entry.dart';

class CartScreen extends StatelessWidget {
  final List<CartItemEntry> cartItems;

  const CartScreen({
    super.key,
    required this.cartItems,
  });

  int get _totalPrice =>
      cartItems.fold(0, (sum, entry) => sum + entry.totalPrice);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        centerTitle: true,
      ),
      body: cartItems.isEmpty
          ? const Center(
              child: Text('Your cart is empty'),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final entry = cartItems[index];
                      final item = entry.item;

                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                          'x${entry.quantity} • ₹${item.price} each',
                        ),
                        trailing: Text(
                          '₹${entry.totalPrice}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 4,
                        color: Colors.black12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ₹$_totalPrice',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
