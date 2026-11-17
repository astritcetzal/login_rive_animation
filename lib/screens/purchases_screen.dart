import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/error_view.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  // URL base de la API de Spring Boot (puerto 8090)
  // - Web / iOS Simulator / macOS: http://localhost:8090
  // - Emulador Android: http://10.0.2.2:8090
  // - Celular físico: http://IP_DE_TU_COMPUTADORA:8090
  static const String baseUrl = 'http://localhost:8090';

  late Future<List<dynamic>> _purchasesFuture;

  @override
  void initState() {
    super.initState();
    _purchasesFuture = fetchPurchases();
  }

  // GET /purchases/all
  Future<List<dynamic>> fetchPurchases() async {
    var response = await http.get(Uri.parse('$baseUrl/purchases/all'));

    // Compatibilidad con el backend actual, que también expone /purchase/
    if (response.statusCode == 404) {
      response = await http.get(Uri.parse('$baseUrl/purchase/'));
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('El servidor respondió ${response.statusCode}');
    }
  }

  void _retry() {
    setState(() {
      _purchasesFuture = fetchPurchases();
    });
  }

  // Suma el total de los artículos de una compra.
  double _total(dynamic purchase) {
    final items = purchase['items'];
    if (items is! List) return 0;

    return items.fold<double>(0, (sum, item) {
      final total = item is Map ? item['total'] : null;
      return sum + (double.tryParse(total?.toString() ?? '') ?? 0);
    });
  }

  int _itemCount(dynamic purchase) {
    final items = purchase['items'];
    return items is List ? items.length : 0;
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'Sin fecha';

    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  String _text(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'No especificado' : text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compras registradas'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _retry,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _purchasesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorView(
              message: 'No pudimos cargar las compras.\n'
                  'Verifica que el servidor esté encendido.',
              onRetry: _retry,
            );
          }

          final purchases = snapshot.data ?? [];

          if (purchases.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Todavía no hay compras registradas',
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
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              final purchase = purchases[index];
              return _PurchaseCard(
                purchase: purchase,
                date: _formatDate(purchase['date']),
                total: _total(purchase),
                itemCount: _itemCount(purchase),
                text: _text,
              );
            },
          );
        },
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({
    required this.purchase,
    required this.date,
    required this.total,
    required this.itemCount,
    required this.text,
  });

  final dynamic purchase;
  final String date;
  final double total;
  final int itemCount;
  final String Function(dynamic value) text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.receipt_long,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Compra #${purchase['purchaseId'] ?? 's/n'}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Cliente',
              value: text(purchase['clientId']),
            ),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Fecha',
              value: date,
            ),
            _InfoRow(
              icon: Icons.payments_outlined,
              label: 'Pago',
              value: text(purchase['paymentMethod']),
            ),
            _InfoRow(
              icon: Icons.inventory_2_outlined,
              label: 'Artículos',
              value: itemCount.toString(),
            ),
            _InfoRow(
              icon: Icons.flag_outlined,
              label: 'Estado',
              value: text(purchase['state']),
            ),
            if ((purchase['comment']?.toString().trim() ?? '').isNotEmpty)
              _InfoRow(
                icon: Icons.comment_outlined,
                label: 'Comentario',
                value: text(purchase['comment']),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
