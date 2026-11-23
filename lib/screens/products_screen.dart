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

 // 1. Lee el nombre de la categoría soportando los posibles nombres del DTO en Java
  String _categoryName(dynamic product) {
    final category = product['category'];

    if (category is Map) {
      final rawName = category['description'] ??
          category['descripcion'] ??
          category['category'] ??
          category['name'];
      if (rawName != null && rawName.toString().trim().isNotEmpty) {
        return rawName.toString();
      }
    }

    // Respaldo por si ProductMapper solo envía categoryId sin el objeto anidado
    if (product['categoryId'] != null) {
      return 'Categoría #${product['categoryId']}';
    }

    return 'Sin categoría';
  }

  // 2. Lee el estado activo soportando 'active' o 'estado'
  String _availability(dynamic product) {
    final category = product['category'];

    if (category is Map) {
      final isActive = category['active'] ?? category['estado'];
      if (isActive != null) {
        return isActive == true ? 'Sí' : 'No';
      }
    }
    return 'No especificado';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú del Restaurante'),
        actions: [
          IconButton(
            tooltip: 'Ver pedidos',
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PurchasesScreen()),
              );
            },
          ),
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay platillos disponibles',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final name = product['name']?.toString() ?? 'Sin nombre';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                    ),
                  ),
                  title: Text(name),
                  subtitle: Text(
                    'Categoría: ${_categoryName(product)}\n'
                    'Disponible: ${_availability(product)}',
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    '\$${product['price'] ?? '0.00'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}