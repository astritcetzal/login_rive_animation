import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../widgets/error_view.dart';
import 'login_screen.dart';
import 'purchases_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  static const Color _bgCream = Color(0xFFFDFBF9);
  static const Color _espresso = Color(0xFF331B24);
  static const Color _titleDark = Color(0xFF1E1E1E);

  late Future<List<dynamic>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = ApiClient.getProducts();
  }

  void _retry() {
    setState(() {
      _productsFuture = ApiClient.getProducts();
    });
  }

  Future<void> _logout() async {
    ApiClient.logout();
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openPurchases() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PurchasesScreen()),
    );
  }

  String _categoryName(dynamic product) {
    final category = product['category'];

    if (category is Map) {
      final rawName = category['descripcion'] ??
          category['description'] ??
          category['category'];
      if (rawName != null && rawName.toString().trim().isNotEmpty) {
        return rawName.toString().trim();
      }
    }

    if (product['categoryId'] != null) {
      return 'Categoría #${product['categoryId']}';
    }

    return 'Sin categoría';
  }

  bool _isAvailable(dynamic product) {
    final category = product['category'];
    if (category is Map) {
      return category['active'] == true;
    }
    return false;
  }

  int _crossAxisCountForWidth(double width) {
    if (width < 420) return 1;
    if (width < 600) return 2;
    if (width < 950) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = _crossAxisCountForWidth(width);

    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        toolbarHeight: kToolbarHeight,
        backgroundColor: _bgCream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Center(
            child: IconButton(
              tooltip: 'Ver pedidos',
              icon: const Icon(
                Icons.shopping_bag_outlined,
                color: _espresso,
              ),
              onPressed: _openPurchases,
            ),
          ),
          const SizedBox(width: 4),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton.icon(
                onPressed: _logout,
                style: FilledButton.styleFrom(
                  backgroundColor: _espresso,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text('Cerrar sesión'),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Text(
              '¿Qué se te antoja hoy?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _titleDark,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _espresso),
                  );
                }

                if (snapshot.hasError) {
                  return ErrorView(
                    message: 'No pudimos cargar el menú.\n'
                        'Verifica que el servidor esté encendido.',
                    onRetry: _retry,
                  );
                }

                final products = snapshot.data ?? [];

                if (products.isEmpty) {
                  return const _EmptyMenuView();
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisExtent: 165,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final rawName = product['name']?.toString().trim();
                    final name = (rawName != null && rawName.isNotEmpty)
                        ? rawName
                        : 'Sin nombre';
                    final isAvailable = _isAvailable(product);

                    return _MenuGridCard(
                      name: name,
                      category: _categoryName(product),
                      price: '${product['price'] ?? '0.00'}',
                      isAvailable: isAvailable,
                      availabilityLabel: isAvailable ? 'Disponible' : 'Agotado',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryVisual {
  const _CategoryVisual({
    required this.icon,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color backgroundColor;

  static const _CategoryVisual _defaultVisual = _CategoryVisual(
    icon: Icons.restaurant_menu_rounded,
    backgroundColor: Color(0xFFEAF2F8),
  );

  static const List<({List<String> keywords, _CategoryVisual visual})> _rules =
      [
    (
      keywords: ['entrada', 'botana'],
      visual: _CategoryVisual(
        icon: Icons.tapas_rounded,
        backgroundColor: Color(0xFFF5E8EC),
      ),
    ),
    (
      keywords: ['sopa', 'caldo'],
      visual: _CategoryVisual(
        icon: Icons.soup_kitchen_rounded,
        backgroundColor: Color(0xFFFFF3E0),
      ),
    ),
    (
      keywords: ['taco', 'antojito'],
      visual: _CategoryVisual(
        icon: Icons.lunch_dining_rounded,
        backgroundColor: Color(0xFFFCE4EC),
      ),
    ),
    (
      keywords: ['plato', 'fuerte'],
      visual: _CategoryVisual(
        icon: Icons.dinner_dining_rounded,
        backgroundColor: Color(0xFFEAF2F8),
      ),
    ),
    (
      keywords: ['agua', 'fresca'],
      visual: _CategoryVisual(
        icon: Icons.local_drink_rounded,
        backgroundColor: Color(0xFFE0F2F1),
      ),
    ),
    (
      keywords: ['caliente', 'café', 'cafe'],
      visual: _CategoryVisual(
        icon: Icons.coffee_rounded,
        backgroundColor: Color(0xFFEFEBE9),
      ),
    ),
    (
      keywords: ['refresco', 'embotellada'],
      visual: _CategoryVisual(
        icon: Icons.liquor_rounded,
        backgroundColor: Color(0xFFEDE7F6),
      ),
    ),
  ];

  factory _CategoryVisual.fromCategory(String categoryName) {
    final normalized = categoryName.toLowerCase().trim();

    for (final rule in _rules) {
      if (rule.keywords.any(normalized.contains)) {
        return rule.visual;
      }
    }

    return _defaultVisual;
  }
}

class _MenuGridCard extends StatelessWidget {
  const _MenuGridCard({
    required this.name,
    required this.category,
    required this.price,
    required this.isAvailable,
    required this.availabilityLabel,
  });

  static const Color _espresso = Color(0xFF331B24);
  static const Color _mutedGray = Color(0xFF8E8E93);
  static const Color _titleDark = Color(0xFF1E1E1E);

  final String name;
  final String category;
  final String price;
  final bool isAvailable;
  final String availabilityLabel;

  @override
  Widget build(BuildContext context) {
    final categoryVisual = _CategoryVisual.fromCategory(category);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: categoryVisual.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    categoryVisual.icon,
                    size: 22,
                    color: _espresso,
                  ),
                ),
                _AvailabilityPill(
                  isAvailable: isAvailable,
                  label: availabilityLabel,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _titleDark,
                height: 1.18,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: _mutedGray,
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '\$$price',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _espresso,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({
    required this.isAvailable,
    required this.label,
  });

  final bool isAvailable;
  final String label;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isAvailable ? const Color(0xFFE7F6EC) : const Color(0xFFFCE8E8);
    final textColor =
        isAvailable ? const Color(0xFF1F7A3E) : const Color(0xFFB42318);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _EmptyMenuView extends StatelessWidget {
  const _EmptyMenuView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFF5E8EC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                size: 48,
                color: Color(0xFF331B24),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay platillos disponibles',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1E1E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}