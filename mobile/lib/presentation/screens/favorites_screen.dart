import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/error_mapper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/product_model.dart';
import '../../domain/repositories/product_repository.dart';
import '../widgets/app_state_views.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<ProductModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ProductModel>> _load() async {
    final repo = context.read<ProductRepository>();
    return repo.getFavorites();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.favorite_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            const Text('Favorilerim'),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: () async {
          _refresh();
          await _future;
        },
        child: FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingBody(message: 'Favoriler yükleniyor…');
            }
            if (snapshot.hasError) {
              return AppRefreshableScrollable(
                child: AppErrorState(
                  message: userFacingErrorMessage(snapshot.error!),
                  onRetry: _refresh,
                ),
              );
            }
            final items = snapshot.data!;
            if (items.isEmpty) {
              return AppRefreshableScrollable(
                child: const AppEmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: 'Favori ürünün yok',
                  subtitle: 'Beğendiğin ürünleri kalp ikonuna tıklayarak buraya ekleyebilirsin.',
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final p = items[index];
                return ProductCard(
                  product: p,
                  onTap: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(productId: p.id),
                          ),
                        )
                        .then((_) => _refresh());
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
