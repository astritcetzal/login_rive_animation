import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/error_view.dart';
import 'login_screen.dart';
import 'purchases_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  // 6.1 Parámetro clave: URL base de la API de Spring Boot (puerto 8090)
  // - Web / iOS Simulator / macOS: usar http://localhost:8090
  // - Emulador Android: cambiar localhost por 10.0.2.2 (http://10.0.2.2:8090)
  // - Celular físico: usar la IP de tu computadora (ej. http://192.168.1.X:8090)
  static const String baseUrl = 'http://localhost:8090';

  late Future<List<dynamic>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = fetchProducts();
  }

  // 6.2 Función para pedir la lista de productos al endpoint GET /products
  Future<List<dynamic>> fetchProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('El servidor respondió ${response.statusCode}');
    }
  }

  // Vuelve a lanzar la petición cuando el usuario toca "Reintentar".
  void _retry() {
    setState(() {
      _productsFuture = fetchProducts();
    });
  }

  // Cierra la sesión de Firebase y regresa al Login limpiando la navegación.
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // 6.4 Lee la categoría anidada del producto: product['category']['category']
  String _categoryName(dynamic product) {
    final category = product['category'];

    if (category is Map && category['category'] != null) {
      return category['category'].toString();
    }
    return 'Sin categoría';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            tooltip: 'Ver compras',
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
      // 6.3 FutureBuilder: espera la respuesta de la API y dibuja el resultado
      body: FutureBuilder<List<dynamic>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          // Mientras responde el servidor, mostrar indicador de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Si hubo un error de conexión, mostrar una pantalla amigable
          if (snapshot.hasError) {
            return ErrorView(
              message: 'No pudimos cargar los productos.\n'
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
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay productos disponibles',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          // 6.4 Mostrar los elementos de la base de datos en una lista sencilla
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final name = product['name'].toString();

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
                    'Stock: ${product['stock']}',
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    '\$${product['price']}',
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
