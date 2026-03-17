import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String title;
  final double price;
  final double? originalPrice;
  final String? image;
  final String category; // Added category
  int quantity;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    this.originalPrice,
    this.image,
    required this.category, // Added category
    required this.quantity,
  });
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }
  
  int get totalItemsCount {
    var count = 0;
    _items.forEach((key, cartItem) {
      count += cartItem.quantity;
    });
    return count;
  }

  void addItem(String productId, double price, String title, String? image, String category, double? originalPrice) {
    print("CartProvider: Adding item $productId, $title");
    if (_items.containsKey(productId)) {
      // increase quantity
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          title: existingCartItem.title,
          price: existingCartItem.price,
          originalPrice: existingCartItem.originalPrice, // Keep existing original price
          image: existingCartItem.image,
          category: existingCartItem.category, 
          quantity: existingCartItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: productId,
          title: title,
          price: price,
          originalPrice: originalPrice,
          image: image,
          category: category,
          quantity: 1,
        ),
      );
    }
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (_items[productId]!.quantity > 1) {
      _items.update(
          productId,
          (existingCartItem) => CartItem(
                id: existingCartItem.id,
                title: existingCartItem.title,
                price: existingCartItem.price,
                originalPrice: existingCartItem.originalPrice,
                image: existingCartItem.image,
                category: existingCartItem.category,
                quantity: existingCartItem.quantity - 1,
              ));
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }
  
  int getQuantity(String productId) {
    if (!_items.containsKey(productId)) {
      return 0;
    }
    return _items[productId]!.quantity;
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
