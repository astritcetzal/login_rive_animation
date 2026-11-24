import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../widgets/error_view.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  static const Color _bgCream = Color(0xFFFDFBF9);
  static const Color _espresso = Color(0xFF331B24);
  static const Color _titleDark = Color(0xFF1E1E1E);

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
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: _bgCream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _espresso,
        title: const Text(
          'Pedidos registrados',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _titleDark,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Actualizar',
              icon: const Icon(Icons.refresh_rounded, color: _espresso),
              onPressed: _retry,
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _purchasesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _espresso),
            );
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
            return const _EmptyPurchasesView();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: purchases.length + 1,
            separatorBuilder: (_, index) =>
                SizedBox(height: index == 0 ? 16 : 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _PurchasesHeaderBanner(orderCount: purchases.length);
              }

              final purchase = purchases[index - 1];
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

class _PurchasesHeaderBanner extends StatelessWidget {
  const _PurchasesHeaderBanner({required this.orderCount});

  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _espresso = Color(0xFF331B24);
  static const Color _titleDark = Color(0xFF1E1E1E);

  final int orderCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: _softBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 28,
              color: _espresso,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen de Pedidos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _titleDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$orderCount ${orderCount == 1 ? 'pedido registrado' : 'pedidos registrados'}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _espresso.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  static const Color _pastelIceBlue = Color(0xFFEAF2F8);
  static const Color _espresso = Color(0xFF331B24);
  static const Color _titleDark = Color(0xFF1E1E1E);

  final dynamic purchase;
  final double total;
  final int itemCount;
  final String Function(dynamic value) text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _pastelIceBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: _espresso,
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pedido #${purchase['orderId'] ?? 's/n'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _titleDark,
                    ),
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _espresso,
                  ),
                ),
              ],
            ),
            Divider(
              height: 24,
              thickness: 1,
              color: _espresso.withValues(alpha: 0.08),
            ),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Cliente',
                    value: text(purchase['clientId']),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.table_restaurant_outlined,
                    label: 'Mesa',
                    value: text(purchase['tableId']),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.payments_outlined,
                    label: 'Método de pago',
                    value: text(purchase['paymentMethod']),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.inventory_2_outlined,
                    label: 'Artículos',
                    value: itemCount.toString(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  static const Color _espresso = Color(0xFF331B24);
  static const Color _titleDark = Color(0xFF1E1E1E);
  static const Color _mutedGray = Color(0xFF6E6E73);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 16,
            color: _espresso.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _mutedGray,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _titleDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyPurchasesView extends StatelessWidget {
  const _EmptyPurchasesView();

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
                color: Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: Color(0xFF331B24),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Todavía no hay pedidos registrados',
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
