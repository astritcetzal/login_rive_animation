import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../widgets/error_view.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  late Future<List<dynamic>> _purchasesFuture;

  @override
  void initState() {
    super.initState();
    _purchasesFuture = ApiClient.getOrders();
  }

  void _retry() {
    setState(() {
      _purchasesFuture = ApiClient.getOrders();
    });
  }

  // Suma el total de los artículos usando la llave correcta 'details'
  double _total(dynamic purchase) {
    final details = purchase['details'];
    if (details is! List) return 0;

    return details.fold<double>(0, (sum, item) {
      final total = item is Map ? item['total'] : null;
      return sum + (double.tryParse(total?.toString() ?? '') ?? 0);
    });
  }

  int _itemCount(dynamic purchase) {
    final details = purchase['details'];
    return details is List ? details.length : 0;
  }

  String _text(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'No especificado' : text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos registrados'),
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
              message: 'No pudimos cargar los pedidos.\n'
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
                      'Todavía no hay pedidos registrados',
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
    required this.total,
    required this.itemCount,
    required this.text,
  });

  final dynamic purchase;
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
                    'Pedido #${purchase['orderId'] ?? 's/n'}',
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
              icon: Icons.table_restaurant_outlined,
              label: 'Mesa',
              value: text(purchase['tableId']),
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