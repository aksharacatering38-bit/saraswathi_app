import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/menu_item.dart';
import 'services/menu_service.dart';
import 'cart_screen.dart';

/// Simple cart entry model
class CartItemEntry {
  final MenuItemModel item;
  int quantity;

  CartItemEntry({required this.item, this.quantity = 1});
}

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  // Services
  final MenuService _menuService = MenuService();

  // Razorpay
  late Razorpay _razorpay;

  // Cart
  final List<CartItemEntry> _cart = [];

  // Categories
  final List<String> _categories = const [
    'All',
    'Recommended',
    'Breads',
    'Curries',
    'Other',
  ];
  String _selectedCategory = 'All';

  // Phone memory (for orders / history)
  String? _lastPhone;

  // Current order (for saving into Supabase after payment)
  String? _currentOrderPhone;
  int _currentOrderAmountPaise = 0;
  List<CartItemEntry> _currentOrderItems = [];

  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // CALL RESTAURANT
  // ---------------------------------------------------------------------------
  Future<void> _callRestaurant() async {
    final uri = Uri(scheme: 'tel', path: '9959730602');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open dialer')),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CART HANDLING
  // ---------------------------------------------------------------------------
  void _addToCart(MenuItemModel item) {
    final existing = _cart.where((c) => c.item.id == item.id);
    if (existing.isNotEmpty) {
      setState(() {
        existing.first.quantity++;
      });
    } else {
      setState(() {
        _cart.add(CartItemEntry(item: item, quantity: 1));
      });
    }
  }

  int get _cartTotalRupees =>
      _cart.fold(0, (sum, c) => sum + (c.item.price * c.quantity));

  // ---------------------------------------------------------------------------
  // ASK FOR PHONE NUMBER (used for payment + history)
  // ---------------------------------------------------------------------------
  Future<String?> _askForPhone({String? initial}) async {
    final controller = TextEditingController(text: initial ?? _lastPhone ?? '');

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter your phone number'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: '10-digit mobile number',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final phone = controller.text.trim();
                Navigator.of(context).pop(phone.isEmpty ? null : phone);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // PAYMENT FLOW
  // ---------------------------------------------------------------------------
  Future<void> _startPayment() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    // Ask for phone number
    final phone = await _askForPhone();
    if (phone == null) return;

    _lastPhone = phone;

    // Amount in paise
    final int amountPaise = _cart.fold(
      0,
      (sum, c) => sum + (c.item.price * c.quantity * 100),
    );

    try {
      // Call Supabase Edge Function to create Razorpay order
      final response = await http.post(
        Uri.parse(
          'https://hukprbgcrjfmrwrxlyif.supabase.co/functions/v1/create-payment-order',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amountPaise, 'userId': phone}),
      );

      if (response.statusCode != 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment creation failed (${response.statusCode})',
            ),
          ),
        );
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final orderId =
          (data['id'] ?? data['order_id'] ?? '') as String; // Razorpay order id

      if (orderId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid order id from server')),
        );
        return;
      }

      // Save "current order" info so we can insert into Supabase on success
      _currentOrderPhone = phone;
      _currentOrderAmountPaise = amountPaise;
      _currentOrderItems = _cart
          .map(
            (e) => CartItemEntry(item: e.item, quantity: e.quantity),
          )
          .toList();

      final options = {
        'key': 'rzp_live_RnSm47ymDxiKnm',
        'amount': amountPaise,
        'name': 'Saraswathi Tiffins',
        'description': 'Order Payment',
        'order_id': orderId,
        'prefill': {
          'contact': phone,
          'email': '',
        },
      };

      _razorpay.open(options);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment error: $e')),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // PAYMENT HANDLERS
  // ---------------------------------------------------------------------------
  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment Successful!')),
    );

    // Save order to Supabase
    try {
      await _saveOrderToSupabase(
        paymentId: response.paymentId,
        razorpayOrderId: response.orderId,
      );

      // Clear cart after successful save
      setState(() {
        _cart.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order save error: $e')),
      );
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment Failed: ${response.code} - ${response.message}',
        ),
      ),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External Wallet: ${response.walletName}'),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SAVE ORDER TO SUPABASE
  // ---------------------------------------------------------------------------
  Future<void> _saveOrderToSupabase({
    String? paymentId,
    String? razorpayOrderId,
  }) async {
    final phone = _currentOrderPhone;
    if (phone == null ||
        _currentOrderItems.isEmpty ||
        _currentOrderAmountPaise == 0) {
      return;
    }

    final itemsJson = _currentOrderItems
        .map(
          (e) => {
            'name': e.item.name,
            'price': e.item.price,
            'quantity': e.quantity,
          },
        )
        .toList();

    final amountRupees = _currentOrderAmountPaise ~/ 100;

    await _supabase.from('orders').insert({
      'user_phone': phone,
      'items': itemsJson,
      'amount': amountRupees,
      'status': 'paid', // initial status
      // you already have created_at default in table
      // additional optional metadata:
      'payment_id': paymentId,
      'razorpay_order_id': razorpayOrderId,
    });

    // Reset current order cache
    _currentOrderPhone = null;
    _currentOrderItems = [];
    _currentOrderAmountPaise = 0;
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saraswathi Tiffins'),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: _callRestaurant,
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CartScreen(cart: _cart),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Order history',
            onPressed: () async {
              // Ask phone if not yet stored
              String? phone = _lastPhone;
              if (phone == null) {
                phone = await _askForPhone();
                if (phone == null) return;
                _lastPhone = phone;
              }

              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderHistoryScreen(
                    phone: phone!,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<MenuItemModel>>(
        future: _menuService.getMenuItems(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          final filtered = _selectedCategory == 'All'
              ? items
              : items
                  .where((e) => e.category == _selectedCategory)
                  .toList();

          return Column(
            children: [
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _categories.map((cat) {
                    final selected = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: selected ? Colors.orange : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: Image.network(
                          item.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                        title: Text(item.name),
                        subtitle: Text('₹${item.price}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _addToCart(item),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_cart.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 4,
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Items: ${_cart.length}'),
                          Text(
                            'Total: ₹$_cartTotalRupees',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _startPayment,
                        child: const Text('Pay & Place Order'),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ORDER HISTORY SCREEN
// -----------------------------------------------------------------------------
class OrderHistoryScreen extends StatefulWidget {
  final String phone;

  const OrderHistoryScreen({super.key, required this.phone});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final stream = _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_phone', widget.phone)
        .order('created_at', ascending: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders (${widget.phone})'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet.'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final amount = order['amount'] ?? 0;
              final status = (order['status'] ?? 'pending').toString();
              final createdAt = order['created_at']?.toString() ?? '';
              final items = (order['items'] as List<dynamic>? ?? [])
                  .cast<Map<String, dynamic>>();

              final itemSummary = items
                  .map((i) =>
                      '${i['name']} x${i['quantity'] ?? 1}')
                  .join(', ');

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text('₹$amount  •  $status'),
                  subtitle: Text('$itemSummary\n$createdAt'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
