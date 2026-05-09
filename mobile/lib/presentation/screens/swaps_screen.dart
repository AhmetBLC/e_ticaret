import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/app_route_observer.dart';
import '../../core/network/error_mapper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/pagination_model.dart';
import '../../data/models/swap_model.dart';
import '../../domain/repositories/swap_repository.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_state_views.dart';
import '../widgets/escrow_info_row.dart';
import '../widgets/status_badges.dart';
import '../widgets/credit_card_form.dart';

class SwapsScreen extends StatefulWidget {
  const SwapsScreen({super.key});

  @override
  State<SwapsScreen> createState() => _SwapsScreenState();
}

class _SwapsScreenState extends State<SwapsScreen> with RouteAware {
  late Future<({List<SwapModel> swaps, PaginationModel? pagination})>
      _future;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refresh();
  }

  Future<({List<SwapModel> swaps, PaginationModel? pagination})> _load() async {
    final repo = context.read<SwapRepository>();
    return repo.listMySwaps(page: 1, limit: 100);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _accept(SwapModel s) async {
    final offeredPrice = s.offeredProduct?.price ?? 0;
    final requestedPrice = s.requestedProduct?.price ?? 0;
    final diff = offeredPrice - requestedPrice;
    
    String? lastFour;
    String? brand;

    if (diff > 0) {
      // You owe money. Show dialog.
      final cardFormKey = GlobalKey<CreditCardFormState>();

      final result = await showDialog<CreditCardFormData>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Fiyat Farkı Ödemesi'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Karşı tarafın ürünü daha pahalı olduğu için ${diff.toStringAsFixed(2)} ₺ ödemeniz gerekiyor. (Atölye onaylayıncaya kadar güvende kalır).',
                  ),
                  const SizedBox(height: 16),
                  CreditCardForm(key: cardFormKey),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () {
                  final cardData = cardFormKey.currentState?.validateAndGet();
                  if (cardData == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Kredi kartı bilgilerini eksiksiz girin')),
                    );
                    return;
                  }
                  Navigator.pop(ctx, cardData);
                },
                child: const Text('Öde ve Kabul Et'),
              ),
            ],
          );
        },
      );

      if (result == null) {
        return; // user cancelled
      }

      lastFour = result.lastFour;
      brand = result.brand;
    }
    setState(() => _busy.add(s.id));
    try {
      final escrow = await context.read<SwapRepository>().acceptSwap(s.id, cardLastFour: lastFour, cardBrand: brand);
      if (!mounted) {
        return;
      }
      var msg = 'Takas kabul edildi. Atölye onayı bekleniyor.';
      if (escrow != null) {
        msg +=
            ' Fiyat farkı emanet altında: ${escrow.amount.toStringAsFixed(2)}.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy.remove(s.id));
      }
    }
  }

  Future<void> _reject(SwapModel s) async {
    setState(() => _busy.add(s.id));
    try {
      await context.read<SwapRepository>().rejectSwap(s.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Takas reddedildi.')),
      );
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy.remove(s.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.id;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: AppColors.accent, size: 24),
            const SizedBox(width: 8),
            const Text('Takaslarım'),
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
              return const AppLoadingBody(message: 'Takaslar yükleniyor…');
            }
            if (snapshot.hasError) {
              return AppRefreshableScrollable(
                child: AppErrorState(
                  message: userFacingErrorMessage(snapshot.error!),
                  onRetry: _refresh,
                ),
              );
            }
            final data = snapshot.data!;
            final swaps = data.swaps;
            if (swaps.isEmpty) {
              return AppRefreshableScrollable(
                child: const AppEmptyState(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Henüz takas yok',
                  subtitle:
                      'Bir ürün sayfasından takas teklifi gönderdiğinizde burada görünür.',
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: swaps.length,
              itemBuilder: (context, i) {
                final s = swaps[i];
                final offered = s.offeredProduct?.title ?? s.productOfferedId;
                final requested =
                    s.requestedProduct?.title ?? s.productRequestedId;
                final incoming =
                    userId != null && s.isIncomingFor(userId);
                final busy = _busy.contains(s.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                      color: isDark ? AppColors.darkDivider.withOpacity(0.5) : const Color(0xFFE8E8E8),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Swap visual: product ⇄ product
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.brand.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            offered,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            gradient: AppColors.accentGradient,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.swap_horiz_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            requested,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SwapStatusBadge(status: s.status),
                        ),
                        if (s.escrow != null) ...[
                          const SizedBox(height: 10),
                          EscrowInfoRow(escrow: s.escrow!),
                        ],
                        if (s.trackingNumber != null && s.trackingNumber!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.local_shipping_rounded,
                                size: 18,
                                color: AppColors.brand,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Takip No',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                        if (s.cargoStatus != null)
                                          ShipmentStatusBadge(status: s.cargoStatus!),
                                      ],
                                    ),
                                    SelectableText(
                                      s.trackingNumber!,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (incoming) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: busy ? null : AppColors.accentGradient,
                                    color: busy ? Colors.grey : null,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: busy ? null : () => _accept(s),
                                      child: Center(
                                        child: busy
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                'Kabul Et',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.error.withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: busy ? null : () => _reject(s),
                                      child: Center(
                                        child: Text(
                                          'Reddet',
                                          style: GoogleFonts.poppins(
                                            color: AppColors.error,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
