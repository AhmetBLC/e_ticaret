import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/user_roles.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../providers/auth_provider.dart';
import '../providers/product_catalog_provider.dart';
import '../widgets/app_state_views.dart';
import '../widgets/product_card.dart';
import 'auth_screen.dart';
import 'favorites_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  late final ProductCatalogProvider _catalog;
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _catalog = context.read<ProductCatalogProvider>();
    _catalog.addListener(_onCatalogChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _catalog.loadFirstPage();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onCatalogChanged() {
    final catalog = _catalog;
    if (!mounted ||
        catalog.error == null ||
        catalog.products.isEmpty ||
        catalog.loadingMore) {
      return;
    }
    final msg = catalog.error!;
    catalog.clearError();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        action: SnackBarAction(
          label: 'Tamam',
          onPressed: () {},
        ),
      ),
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final pos = _scrollController.position;
    if (pos.pixels > pos.maxScrollExtent - 400) {
      context.read<ProductCatalogProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _catalog.removeListener(_onCatalogChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<ProductCatalogProvider>();
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: () => catalog.refresh(),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Bar: Logo + Location + Avatar
                      Row(
                        children: [
                          // Brand Name
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                AppColors.brandGradient.createShader(bounds),
                            child: Text(
                              'TakasApp',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // City selector
                          PopupMenuButton<String>(
                            initialValue: catalog.city,
                            onSelected: (val) {
                              catalog.setFilters(
                                city: val == 'Tüm Türkiye' ? null : val,
                              );
                            },
                            itemBuilder: (ctx) => [
                              'Tüm Türkiye',
                              'İstanbul',
                              'Ankara',
                              'İzmir',
                              'Bursa',
                              'Antalya'
                            ]
                                .map((c) =>
                                    PopupMenuItem(value: c, child: Text(c)))
                                .toList(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfaceVariant
                                    : AppColors.lightSurfaceVariant,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkDivider
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: AppColors.brand,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    catalog.city ?? 'Türkiye',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Profile Avatar
                          GestureDetector(
                            onTap: () => Navigator.of(context)
                                .pushNamed(AppRoutes.account),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: AppColors.brandGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Search Bar ──────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.buttonRadius),
                          color: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.lightSurfaceVariant,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkDivider
                                : const Color(0xFFE5E7EB),
                            width: 0.5,
                          ),
                        ),
                        child: TextField(
                          onChanged: (val) {
                            catalog.setFilters(
                              query: val,
                              city: catalog.city,
                            );
                          },
                          style: theme.textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Araba, Telefon, Bisiklet ara...',
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppColors.brand.withOpacity(0.7),
                            ),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Categories ──────────────────────────
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _CategoryChip(
                              label: 'Hepsi',
                              icon: Icons.grid_view_rounded,
                              isSelected: catalog.categoryId == null,
                            ),
                            _CategoryChip(
                              label: 'Elektronik',
                              icon: Icons.phone_android,
                              isSelected: false,
                            ),
                            _CategoryChip(
                              label: 'Moda',
                              icon: Icons.checkroom,
                              isSelected: false,
                            ),
                            _CategoryChip(
                              label: 'Ev Eşyası',
                              icon: Icons.chair_outlined,
                              isSelected: false,
                            ),
                            _CategoryChip(
                              label: 'Spor',
                              icon: Icons.fitness_center,
                              isSelected: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Section Title ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Vitrin',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.swap_horiz_rounded,
                        color: AppColors.brand,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Takas yapılabilir',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Product Grid ──────────────────────────────
              if (catalog.loading && catalog.products.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.brand),
                  ),
                )
              else if (catalog.products.isEmpty)
                SliverFillRemaining(
                  child: AppEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Sonuç bulunamadı',
                    subtitle:
                        'Arama kriterlerini değiştirerek tekrar deneyebilirsiniz.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.68,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= catalog.products.length) {
                          return const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.brand,
                              ),
                            ),
                          );
                        }
                        final p = catalog.products[index];
                        return ProductCard(
                          product: p,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(productId: p.id),
                              ),
                            );
                          },
                        );
                      },
                      childCount:
                          catalog.products.length + (catalog.hasMore ? 1 : 0),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),

      // ── FAB ─────────────────────────────────────────────
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.createListing),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          label: Text(
            'İlan Ver',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          icon: const Icon(Icons.add_a_photo_rounded),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // ── Bottom Navigation ─────────────────────────────
      bottomNavigationBar: Container(
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
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          items: [
            _buildNavItem(Icons.home_rounded, Icons.home_outlined, 'Vitrin'),
            _buildNavItem(
                Icons.chat_rounded, Icons.chat_bubble_outline_rounded, 'Sohbet'),
            _buildNavItem(Icons.swap_horiz_rounded,
                Icons.swap_horiz_rounded, 'Takas'),
            _buildNavItem(
                Icons.favorite_rounded, Icons.favorite_border_rounded, 'Favoriler'),
            _buildNavItem(Icons.person_rounded, Icons.person_outline_rounded,
                'Hesabım'),
          ],
          onTap: (index) {
            setState(() => _currentNavIndex = index);
            if (index == 1) {
              Navigator.of(context).pushNamed(AppRoutes.conversations);
            } else if (index == 2) {
              Navigator.of(context).pushNamed(AppRoutes.swaps);
            } else if (index == 3) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            } else if (index == 4) {
              Navigator.of(context).pushNamed(AppRoutes.account);
            }
          },
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    return BottomNavigationBarItem(
      icon: Icon(inactiveIcon),
      activeIcon: Icon(activeIcon),
      label: label,
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.brandGradient : null,
            color: isSelected
                ? null
                : (isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightSurfaceVariant),
            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
            border: isSelected
                ? null
                : Border.all(
                    color: isDark
                        ? AppColors.darkDivider
                        : const Color(0xFFE5E7EB),
                    width: 0.5,
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
