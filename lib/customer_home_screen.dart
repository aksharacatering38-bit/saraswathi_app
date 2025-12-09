import 'package:flutter/material.dart';
import 'models/menu_item.dart';
import 'models/cart_item_entry.dart';
import 'services/menu_service.dart';
import 'cart_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final MenuService _menuService = MenuService();

  /// cart: key = item.id
  final Map<String, CartItemEntry> _cart = {};

  String _selectedCategory = "All";

  // ----------------- CART CALCULATIONS -----------------
  int get _totalCartItems =>
      _cart.values.fold(0, (sum, entry) => sum + entry.quantity);

  int get _totalCartPrice =>
      _cart.values.fold(0, (sum, entry) => sum + entry.totalPrice);

  // ----------------- CART OPERATIONS -----------------

  void _addToCart(MenuItemModel item) {
    setState(() {
      if (_cart.containsKey(item.id)) {
        _cart[item.id]!.quantity++;
      } else {
        _cart[item.id] = CartItemEntry(item: item, quantity: 1);
      }
    });
  }

  void _removeFromCart(MenuItemModel item) {
    if (!_cart.containsKey(item.id)) return;

    setState(() {
      final entry = _cart[item.id]!;
      if (entry.quantity > 1) {
        entry.quantity--;
      } else {
        _cart.remove(item.id);
      }
    });
  }

  void _openCartScreen() {
    if (_cart.isEmpty) return;

    final cartList = _cart.values.toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CartScreen(cart: cartList),
      ),
    );
  }

  Future<void> _showPaymentDialog() async {
    if (_cart.isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Payment"),
          content: Text(
            "Total payable amount is ₹$_totalCartPrice.\n\n"
            "Razorpay integration will be connected.\n"
            "For now, this is a demo confirmation.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // --------------------- UI BUILD ---------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saraswathi Tiffins"),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: _cart.isEmpty ? null : _openCartScreen,
              ),
              if (_totalCartItems > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _totalCartItems.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildHeaderBanner(),
          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<List<MenuItemModel>>(
              stream: _menuService.watchMenuItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Failed to load menu.\n${snapshot.error}",
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const Center(
                    child: Text("Menu is not available right now."),
                  );
                }

                return _buildMenuWithCategories(items);
              },
            ),
          ),

          if (_cart.isNotEmpty) _buildCartSummaryBar(),
        ],
      ),
    );
  }

  // ---------------------- WIDGETS ----------------------

  Widget _buildHeaderBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: const [
          Icon(
            Icons.delivery_dining_rounded,
            size: 32,
            color: Colors.deepOrange,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Evening tiffins delivered before 8:00 PM.\nOrder now and relax!",
              style: TextStyle(fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuWithCategories(List<MenuItemModel> allItems) {
    final categories = <String>{
      "All",
      ...allItems.map((e) => e.category.trim()).where((c) => c.isNotEmpty),
    }.toList();

    final filteredItems = _selectedCategory == "All"
        ? allItems
        : allItems.where((item) => item.category == _selectedCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category == _selectedCategory;

              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedCategory = category);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Menu",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              final cartEntry = _cart[item.id];
              return _buildMenuItemCard(item, cartEntry);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItemCard(MenuItemModel item, CartItemEntry? entry) {
    final quantity = entry?.quantity ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildItemImage(item),
            const SizedBox(width: 10),
            Expanded(child: _buildItemDetails(item, quantity)),
            const SizedBox(width: 8),
            _buildQuantityControls(item, quantity),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage(MenuItemModel item) {
    final hasImage = item.imageUrl != null && item.imageUrl!.trim().isNotEmpty;

    if (!hasImage) {
      return Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_not_supported_outlined),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        item.imageUrl!,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 70,
            height: 70,
            color: Colors.grey.shade100,
            child: const Icon(Icons.image_not_supported_outlined),
          );
        },
      ),
    );
  }

  Widget _buildItemDetails(MenuItemModel item, int quantity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (item.isBestSeller)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Best Seller",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 4),

        if (item.description.trim().isNotEmpty)
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),

        const SizedBox(height: 6),

        Text(
          "₹${item.price}",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          item.category,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),

        if (!item.isAvailable)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              "Currently unavailable",
              style: TextStyle(
                fontSize: 11,
                color: Colors.redAccent,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuantityControls(MenuItemModel item, int quantity) {
    final isAvailable = item.isAvailable;

    if (!isAvailable) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (quantity == 0)
          ElevatedButton(
            onPressed: () => _addToCart(item),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(60, 36),
            ),
            child: const Text("ADD"),
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                iconSize: 20,
                onPressed: () => _removeFromCart(item),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                quantity.toString(),
                style: const TextStyle(fontSize: 14),
              ),
              IconButton(
                iconSize: 20,
                onPressed: () => _addToCart(item),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildCartSummaryBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              color: Colors.black12,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "₹$_totalCartPrice",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "$_totalCartItems item(s) in cart",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _openCartScreen,
              child: const Text("View Cart"),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _showPaymentDialog,
              child: const Text("Pay & Order"),
            ),
          ],
        ),
      ),
    );
  }
}
