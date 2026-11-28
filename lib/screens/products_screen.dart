import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../widgets/error_view.dart';
import 'login_screen.dart';
import 'purchases_screen.dart';

typedef _CategoryOption = ({int id, String name});

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  static const Color _bgCream = Color(0xFFFDFBF9);
  static const Color _espresso = Color(0xFF331B24);
  static const Color _titleDark = Color(0xFF1E1E1E);
  static const String _allCategories = 'Todos';

  late Future<List<dynamic>> _productsFuture;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = _allCategories;
  List<dynamic> _latestProducts = const [];

  @override
  void initState() {
    super.initState();
    _productsFuture = ApiClient.getProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = _allCategories;
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? const Color(0xFFB42318) : _espresso,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  int? _productId(dynamic product) {
    final raw = product['productId'] ?? product['id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  int? _categoryId(dynamic product) {
    final category = product['category'];
    final raw = (category is Map ? (category['categoryId'] ?? category['id']) : null) ??
        product['categoryId'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  String _productName(dynamic product) {
    final rawName = product['name']?.toString().trim();
    return (rawName != null && rawName.isNotEmpty) ? rawName : 'Sin nombre';
  }

  String _categoryName(dynamic product) {
    final category = product['category'];

    if (category is Map) {
      final rawName = category['category'] ??
          category['descripcion'] ??
          category['description'];
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
    final raw = product['available'] ?? product['disponible'];
    if (raw is bool) return raw;
    if (raw != null) return raw.toString().toLowerCase() == 'true';
    return false;
  }

  String _availabilityKey(dynamic product) {
    if (product is Map && product.containsKey('disponible')) {
      return 'disponible';
    }
    if (_latestProducts.isNotEmpty &&
        _latestProducts.first is Map &&
        (_latestProducts.first as Map).containsKey('disponible')) {
      return 'disponible';
    }
    return 'available';
  }

  String _formatPrice(dynamic rawPrice) {
    if (rawPrice is num) {
      return '\$${rawPrice.toStringAsFixed(2)}';
    }
    final parsed = num.tryParse(rawPrice?.toString() ?? '');
    if (parsed != null) {
      return '\$${parsed.toStringAsFixed(2)}';
    }
    return '\$${rawPrice ?? '0.00'}';
  }

  List<String> _extractCategories(List<dynamic> products) {
    final seen = <String>{};
    final categories = <String>[_allCategories];

    for (final product in products) {
      final category = _categoryName(product);
      if (seen.add(category)) {
        categories.add(category);
      }
    }

    return categories;
  }

  List<_CategoryOption> _extractCategoryOptions(List<dynamic> products) {
    final seenIds = <int>{};
    final options = <_CategoryOption>[];

    for (final product in products) {
      final id = _categoryId(product);
      if (id != null && seenIds.add(id)) {
        options.add((id: id, name: _categoryName(product)));
      }
    }

    return options;
  }

  List<dynamic> _filterProducts(List<dynamic> products) {
    final query = _searchQuery.trim().toLowerCase();

    return products.where((product) {
      final matchesCategory = _selectedCategory == _allCategories ||
          _categoryName(product) == _selectedCategory;
      final matchesQuery =
          query.isEmpty || _productName(product).toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  int _crossAxisCountForWidth(double width) {
    if (width < 420) return 1;
    if (width < 600) return 2;
    if (width < 950) return 3;
    return 4;
  }

  Future<void> _openProductForm({dynamic product}) async {
    final isEditing = product != null;
    final productId = isEditing ? _productId(product) : null;
    if (isEditing && productId == null) {
      _showMessage('No se encontró el ID del platillo.', isError: true);
      return;
    }

    final categoryOptions = _extractCategoryOptions(_latestProducts);
    final availabilityKey = _availabilityKey(product);

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ProductFormSheet(
        isEditing: isEditing,
        productId: productId,
        initialName: isEditing ? _productName(product) : '',
        initialPrice: isEditing ? '${product['price'] ?? ''}' : '',
        initialCategoryId: isEditing
            ? _categoryId(product)
            : (categoryOptions.isNotEmpty ? categoryOptions.first.id : null),
        initialImageUrl:
            isEditing ? (product['imageUrl']?.toString() ?? '') : '',
        initialAvailable: isEditing ? _isAvailable(product) : true,
        availabilityKey: availabilityKey,
        categoryOptions: categoryOptions,
      ),
    );

    if (!mounted || result == null) return;

    if (result == 'forbidden') {
      _showMessage(
        'No tienes permisos de administrador para modificar el menú',
        isError: true,
      );
      return;
    }

    if (result == 'saved') {
      _retry();
      _showMessage(
        isEditing
            ? 'Platillo actualizado correctamente'
            : 'Platillo registrado correctamente',
      );
    }
  }

  Future<void> _confirmAndDelete(dynamic product) async {
    final id = _productId(product);
    if (id == null) {
      _showMessage('No se encontró el ID del platillo.', isError: true);
      return;
    }

    final name = _productName(product);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _bgCream,
        title: const Text('Eliminar platillo'),
        content: Text('¿Seguro que deseas eliminar "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiClient.deleteProduct(id);
      if (!mounted) return;
      _retry();
      _showMessage('Platillo eliminado correctamente');
    } on ApiForbiddenException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (e) {
      _showMessage('No se pudo eliminar: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = _crossAxisCountForWidth(width);

    return Scaffold(
      backgroundColor: _bgCream,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openProductForm(),
        backgroundColor: _espresso,
        foregroundColor: Colors.white,
        tooltip: 'Nuevo platillo',
        child: const Icon(Icons.add_rounded),
      ),
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
            padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
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
                    message: 'Servidor no disponible',
                    onRetry: _retry,
                  );
                }

                final products = snapshot.data ?? [];
                _latestProducts = products;

                if (products.isEmpty) {
                  return const _EmptyStateView(
                    icon: Icons.restaurant_menu_rounded,
                    message: 'No hay platillos disponibles',
                  );
                }

                final categories = _extractCategories(products);
                final activeCategory = categories.contains(_selectedCategory)
                    ? _selectedCategory
                    : _allCategories;
                final filteredProducts = _filterProducts(products);

                return Column(
                  children: [
                    _SearchAndFilterBar(
                      controller: _searchController,
                      searchQuery: _searchQuery,
                      categories: categories,
                      selectedCategory: activeCategory,
                      onSearchChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      onClearSearch: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      onCategorySelected: (category) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                    Expanded(
                      child: filteredProducts.isEmpty
                          ? _EmptyStateView(
                              icon: Icons.search_off_rounded,
                              message:
                                  'No se encontraron platillos con ese filtro',
                              actionLabel: 'Limpiar filtros',
                              onAction: _clearFilters,
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 88),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisExtent: 274,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                final isAvailable = _isAvailable(product);

                                return _ProductGridCard(
                                  imageUrl:
                                      product['imageUrl']?.toString() ?? '',
                                  name: _productName(product),
                                  category: _categoryName(product),
                                  price: _formatPrice(product['price']),
                                  isAvailable: isAvailable,
                                  onEdit: () =>
                                      _openProductForm(product: product),
                                  onDelete: () => _confirmAndDelete(product),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductFormSheet extends StatefulWidget {
  const _ProductFormSheet({
    required this.isEditing,
    required this.productId,
    required this.initialName,
    required this.initialPrice,
    required this.initialCategoryId,
    required this.initialImageUrl,
    required this.initialAvailable,
    required this.availabilityKey,
    required this.categoryOptions,
  });

  final bool isEditing;
  final int? productId;
  final String initialName;
  final String initialPrice;
  final int? initialCategoryId;
  final String initialImageUrl;
  final bool initialAvailable;
  final String availabilityKey;
  final List<_CategoryOption> categoryOptions;

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  static const Color _espresso = Color(0xFF331B24);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _categoryIdController;
  late final TextEditingController _imageUrlController;

  int? _selectedCategoryId;
  late bool _isAvailable;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _priceController = TextEditingController(text: widget.initialPrice);
    _selectedCategoryId = widget.initialCategoryId;
    _categoryIdController = TextEditingController(
      text: widget.initialCategoryId?.toString() ?? '',
    );
    _imageUrlController = TextEditingController(text: widget.initialImageUrl);
    _isAvailable = widget.initialAvailable;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryIdController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final price = double.tryParse(_priceController.text.trim());
    final categoryId = widget.categoryOptions.isNotEmpty
        ? _selectedCategoryId
        : int.tryParse(_categoryIdController.text.trim());

    if (price == null || categoryId == null) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'price': price,
      'categoryId': categoryId,
      'imageUrl': _imageUrlController.text.trim(),
      widget.availabilityKey: _isAvailable,
    };

    try {
      if (widget.isEditing && widget.productId != null) {
        await ApiClient.updateProduct(widget.productId!, payload);
      } else {
        await ApiClient.createProduct(payload);
      }
      if (!mounted) return;
      Navigator.pop(context, 'saved');
    } on ApiForbiddenException {
      if (!mounted) return;
      Navigator.pop(context, 'forbidden');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = 'Error al guardar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isEditing ? 'Editar platillo' : 'Nuevo platillo',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del platillo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Ingresa el nombre'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresa un precio válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (widget.categoryOptions.isNotEmpty)
                DropdownButtonFormField<int>(
                  initialValue: widget.categoryOptions
                          .any((c) => c.id == _selectedCategoryId)
                      ? _selectedCategoryId
                      : widget.categoryOptions.first.id,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.categoryOptions
                      .map(
                        (cat) => DropdownMenuItem<int>(
                          value: cat.id,
                          child: Text(cat.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                )
              else
                TextFormField(
                  controller: _categoryIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ID de categoría',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Ingresa un ID de categoría válido';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'URL de imagen (Supabase)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Disponibilidad',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _isAvailable ? 'Disponible' : 'Agotado',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isAvailable
                        ? const Color(0xFF1F7A3E)
                        : const Color(0xFFE65100),
                  ),
                ),
                activeThumbColor: const Color(0xFF1F7A3E),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isSaving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _espresso,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.isEditing
                            ? 'Guardar cambios'
                            : 'Registrar platillo',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({
    required this.controller,
    required this.searchQuery,
    required this.categories,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onCategorySelected,
  });

  static const Color _espresso = Color(0xFF331B24);

  final TextEditingController controller;
  final String searchQuery;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: controller,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar platillo...',
              hintStyle: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: _espresso,
              ),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: 'Limpiar búsqueda',
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Color(0xFF8E8E93),
                      ),
                      onPressed: onClearSearch,
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _espresso.withValues(alpha: 0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _espresso.withValues(alpha: 0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: _espresso,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category == selectedCategory;

              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (_) => onCategorySelected(category),
                showCheckmark: false,
                selectedColor: _espresso,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected
                      ? _espresso
                      : _espresso.withValues(alpha: 0.12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : _espresso,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  const _ProductGridCard({
    required this.imageUrl,
    required this.name,
    required this.category,
    required this.price,
    required this.isAvailable,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color _espresso = Color(0xFF331B24);
  static const Color _mutedGray = Color(0xFF8E8E93);
  static const Color _titleDark = Color(0xFF1E1E1E);

  final String imageUrl;
  final String name;
  final String category;
  final String price;
  final bool isAvailable;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                color: const Color(0xFFF3EFEA),
                child: Image.network(
                  imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => const Icon(
                    Icons.image_not_supported,
                    size: 36,
                    color: _mutedGray,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _AvailabilityBadge(isAvailable: isAvailable),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 4),
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
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: onEdit,
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: _espresso,
                        ),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Color(0xFFB42318),
                        ),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        visualDensity: VisualDensity.compact,
                      ),
                      const Spacer(),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _espresso,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isAvailable ? const Color(0xFFE7F6EC) : const Color(0xFFFFF3E0);
    final textColor =
        isAvailable ? const Color(0xFF1F7A3E) : const Color(0xFFE65100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        isAvailable ? 'Disponible' : 'Agotado',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

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
              child: Icon(
                icon,
                size: 48,
                color: const Color(0xFF331B24),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1E1E),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF331B24),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
