import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/user_roles.dart';
import '../../core/network/error_mapper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_variant_model.dart';
import '../../domain/repositories/product_repository.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_state_views.dart';
import '../widgets/checkout_sheet.dart';
import '../widgets/swap_offer_sheet.dart';
import 'auth_screen.dart';
import 'chat_room_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Future<ProductModel>? _future;
  Future<({List<Map<String, dynamic>> reviews, double averageRating, int reviewCount})>? _reviewsFuture;
  ProductVariantModel? _selectedVariant;

  bool _showSwapOfferButton(AuthProvider auth, ProductModel p) {
    if (auth.initializing) {
      return false;
    }
    if (auth.user?.role == UserRoles.admin) {
      return false;
    }
    if (!p.isAvailable) {
      return false;
    }
    if (auth.isAuthenticated && auth.user!.id == p.userId) {
      return false;
    }
    return true;
  }

  Future<void> _openSwapOffer(BuildContext context, ProductModel target) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      if (!context.mounted) {
        return;
      }
      final again = context.read<AuthProvider>();
      if (!again.isAuthenticated) {
        return;
      }
    }
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SwapOfferSheet(
        requestedProductId: target.id,
        requestedTitle: target.title,
        requestedPrice: target.displayPrice,
      ),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Takas teklifi gönderildi.')),
      );
    }
  }

  Future<void> _openCheckout(BuildContext context, ProductModel target) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      if (!context.mounted) return;
      if (!context.read<AuthProvider>().isAuthenticated) return;
    }

    if (target.variants.isNotEmpty && _selectedVariant == null) {
      if (target.variants.length == 1) {
        _selectedVariant = target.variants.first;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen devam etmeden önce bir seçenek seçin.')),
        );
        return;
      }
    }

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => CheckoutSheet(
        productId: target.id,
        title: target.title,
        price: _selectedVariant?.priceOverride ?? target.price,
        variantId: _selectedVariant?.id,
      ),
    );

    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Siparişiniz alındı! Atölye onayı bekleniyor.'),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() {
        _future = context.read<ProductRepository>().getProduct(widget.productId);
      });
    }
  }

  void _toggleFavorite(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      if (!context.mounted) return;
      if (!context.read<AuthProvider>().isAuthenticated) return;
    }
    
    try {
      final isNowFavorited = await context.read<ProductRepository>().toggleFavorite(widget.productId);
      if (context.mounted) {
        setState(() {
          _future = context.read<ProductRepository>().getProduct(widget.productId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNowFavorited ? 'Favorilere eklendi.' : 'Favorilerden çıkarıldı.'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e))),
        );
      }
    }
  }

  void _openChat(BuildContext context, ProductModel p) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      if (!context.mounted) return;
      if (!context.read<AuthProvider>().isAuthenticated) return;
    }
    
    // Open chat room directly (backend handles conversation creation/lookup)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          conversationId: '', // Empty means 'start new for this product'
          productId: p.id,
          title: 'Satıcı ile Sohbet',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _future ??= context.read<ProductRepository>().getProduct(widget.productId);
    _reviewsFuture ??= context.read<ProductRepository>().getProductReviews(widget.productId);

    return FutureBuilder<ProductModel>(
      future: _future!,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: AppLoadingBody(message: 'Ürün yükleniyor…'));
        }
        if (snapshot.hasError) {
          final msg = userFacingErrorMessage(snapshot.error!);
          return Scaffold(
            appBar: AppBar(),
            body: AppRefreshableScrollable(
              child: AppErrorState(
                message: msg,
                onRetry: () => setState(() => _future = null),
              ),
            ),
          );
        }
        final p = snapshot.data!;
        if (p.variants.length == 1 && _selectedVariant == null) {
          _selectedVariant = p.variants.first;
        }
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final auth = context.watch<AuthProvider>();
        final showActions = _showSwapOfferButton(auth, p);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: IconButton(
                  icon: Icon(
                    p.isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: p.isFavorited ? AppColors.error : Colors.white,
                    size: 20,
                  ),
                  onPressed: () => _toggleFavorite(context),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image Gallery ───────────────────────────
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (p.imageUrl != null || p.additionalImages.isNotEmpty)
                        PageView.builder(
                          itemCount: (p.imageUrl != null ? 1 : 0) + p.additionalImages.length,
                          itemBuilder: (context, index) {
                            final images = [if (p.imageUrl != null) p.imageUrl!, ...p.additionalImages];
                            return Image.network(images[index], fit: BoxFit.cover);
                          },
                        )
                      else
                        Container(
                          color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                            ),
                          ),
                        ),
                      
                      // Bottom gradient
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                (isDark ? AppColors.darkBg : AppColors.lightBg).withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Page dots
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            (p.imageUrl != null ? 1 : 0) + p.additionalImages.length,
                            (index) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == 0
                                    ? AppColors.brand
                                    : Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (!p.isAvailable)
                        Container(
                          color: Colors.black.withOpacity(0.5),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'SATILDI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Product Info ────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                AppColors.brandGradient.createShader(bounds),
                            child: Text(
                              '${(_selectedVariant?.priceOverride ?? p.displayPrice).toStringAsFixed(0)} ₺',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.swap_horiz_rounded, size: 14, color: AppColors.accent),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Takas Açık',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (p.favoriteCount > 0) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.favorite_rounded, size: 14, color: AppColors.error.withOpacity(0.7)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${p.favoriteCount} beğeni',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title + Rating
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (p.reviewCount > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    p.averageRating.toStringAsFixed(1),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    ' (${p.reviewCount})',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Variants
                      if (p.variants.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Seçenekler',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: p.variants.map((v) {
                            final isSelected = _selectedVariant?.id == v.id;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedVariant = isSelected ? null : v;
                                });
                              },
                              child: AnimatedContainer(
                                duration: AppDurations.fast,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: isSelected ? AppColors.brandGradient : null,
                                  color: isSelected
                                      ? null
                                      : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? null
                                      : Border.all(
                                          color: isDark ? AppColors.darkDivider : const Color(0xFFE0E0E0),
                                        ),
                                ),
                                child: Text(
                                  v.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 20),
                      Divider(color: theme.colorScheme.outline.withOpacity(0.3)),
                      const SizedBox(height: 16),

                      // Location
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.brand.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.location_on_rounded, color: AppColors.brand, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${p.city ?? 'Lokasyon bilgisi yok'}, ${p.district ?? ''}',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'Açıklama',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.description ?? 'Açıklama belirtilmemiş.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Reviews Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  gradient: AppColors.brandGradient,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Değerlendirmeler',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          TextButton(onPressed: () {}, child: const Text('Tümünü Gör')),
                        ],
                      ),
                      if (p.reviewCount == 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Henüz değerlendirme yapılmamış.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        FutureBuilder(
                          future: _reviewsFuture,
                          builder: (context, revSnapshot) {
                            if (!revSnapshot.hasData) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(color: AppColors.brand),
                                ),
                              );
                            }
                            final reviews = revSnapshot.data!.reviews;
                            if (reviews.isEmpty) {
                              return Text(
                                'Henüz değerlendirme yapılmamış.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              );
                            }
                            
                            return Column(
                              children: reviews.take(3).map((r) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkCard : AppColors.lightSurfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          ...List.generate(5, (index) => Icon(
                                            index < (r['rating'] as int) ? Icons.star_rounded : Icons.star_border_rounded,
                                            color: AppColors.warning,
                                            size: 16,
                                          )),
                                          const SizedBox(width: 8),
                                          Text(
                                            r['user_name'] ?? 'Anonim',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (r['comment'] != null && r['comment'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          r['comment'],
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),

                      const SizedBox(height: 24),

                      // Seller Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightSurfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppColors.brandGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_rounded, size: 26, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Satıcı Bilgileri',
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'Üye since 2024',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (showActions)
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.brand),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextButton.icon(
                                  onPressed: () => _openChat(context, p),
                                  icon: const Icon(Icons.chat_rounded, size: 16),
                                  label: const Text('Mesaj'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.brand,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Action Bar ───────────────────────────
          bottomNavigationBar: showActions
              ? Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB),
                        width: 0.5,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Swap Button
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                              onTap: () => _openSwapOffer(context, p),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 22),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Takas Yap',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Buy Button
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brand.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                              onTap: () => _openCheckout(context, p),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Satın Al',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }
}
