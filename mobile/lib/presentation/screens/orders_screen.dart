import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/app_route_observer.dart';
import '../../core/network/error_mapper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/order_model.dart';
import '../../data/models/pagination_model.dart';
import '../../domain/repositories/order_repository.dart';
import '../widgets/app_state_views.dart';
import '../widgets/status_badges.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with RouteAware {
  late Future<({List<OrderModel> orders, PaginationModel? pagination})>
      _future;

  /// Order ids currently calling `advanceOrderStatus` (demo cargo actions).
  final Set<String> _busyOrderIds = {};

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

  Future<({List<OrderModel> orders, PaginationModel? pagination})> _load() async {
    final repo = context.read<OrderRepository>();
    return repo.listMyOrders(page: 1, limit: 100);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _advanceStatus(String orderId, String nextStatus) async {
    setState(() => _busyOrderIds.add(orderId));
    try {
      final repo = context.read<OrderRepository>();
      await repo.advanceOrderStatus(orderId: orderId, status: nextStatus);
      if (!mounted) return;
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _busyOrderIds.remove(orderId));
      }
    }
  }

  Future<void> _requestReturn(String orderId) async {
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          title: Text('İade Talebi', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'İade Nedeni',
              hintText: 'Neden iade etmek istiyorsunuz?',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
              child: const Text('Gönder'),
            ),
          ],
        );
      },
    );

    if (ok == true && reasonController.text.isNotEmpty) {
      setState(() => _busyOrderIds.add(orderId));
      try {
        final repo = context.read<OrderRepository>();
        await repo.requestReturn(orderId: orderId, reason: reasonController.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İade talebiniz başarıyla iletildi.')),
        );
        _refresh();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e))),
        );
      } finally {
        if (mounted) {
          setState(() => _busyOrderIds.remove(orderId));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shopping_bag_rounded, color: AppColors.brand, size: 24),
            const SizedBox(width: 8),
            const Text('Siparişlerim'),
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
              return const AppLoadingBody(message: 'Siparişler yükleniyor…');
            }
            if (snapshot.hasError) {
              return AppRefreshableScrollable(
                child: AppErrorState(
                  message: userFacingErrorMessage(snapshot.error!),
                  onRetry: _refresh,
                ),
              );
            }
            final orders = snapshot.data!.orders;
            if (orders.isEmpty) {
              return AppRefreshableScrollable(
                child: const AppEmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'Henüz sipariş yok',
                  subtitle: 'Satın aldığınız ürünler burada listelenir.',
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: orders.length,
              itemBuilder: (context, i) {
                final o = orders[i];
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.brand.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.inventory_2_rounded, color: AppColors.brand, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sipariş #${o.id.substring(0, 8).toUpperCase()}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${o.items.length} kalem · '
                                    '${o.createdAt.toLocal().toString().split('.').first}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OrderStatusBadge(status: o.status),
                          ],
                        ),
                        if (o.trackingNumber != null &&
                            o.trackingNumber!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.local_shipping_rounded,
                                    size: 16,
                                    color: AppColors.brand,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Kargo Takip No',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          if (o.cargoStatus != null)
                                            ShipmentStatusBadge(status: o.cargoStatus!),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      SelectableText(
                                        o.trackingNumber!,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (o.status == OrderStatuses.pending ||
                            o.status == OrderStatuses.shipped ||
                            o.status == OrderStatuses.delivered) ...[
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _busyOrderIds.contains(o.id)
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.brand,
                                    ),
                                  )
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.end,
                                    children: [
                                      if (o.status == OrderStatuses.pending)
                                        FilledButton(
                                          onPressed: () => _advanceStatus(
                                            o.id,
                                            OrderStatuses.shipped,
                                          ),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.brand,
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            minimumSize: const Size(0, 36),
                                          ),
                                          child: Text('Kargoya Ver', style: GoogleFonts.poppins(fontSize: 12)),
                                        ),
                                      if (o.status == OrderStatuses.shipped)
                                        FilledButton(
                                          onPressed: () => _advanceStatus(
                                            o.id,
                                            OrderStatuses.delivered,
                                          ),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            minimumSize: const Size(0, 36),
                                          ),
                                          child: Text('Teslim Edildi', style: GoogleFonts.poppins(fontSize: 12)),
                                        ),
                                      if (o.status == OrderStatuses.delivered)
                                        OutlinedButton(
                                          onPressed: () => _requestReturn(o.id),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.error,
                                            side: const BorderSide(color: AppColors.error),
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            minimumSize: const Size(0, 36),
                                          ),
                                          child: Text('İade Et', style: GoogleFonts.poppins(fontSize: 12)),
                                        ),
                                    ],
                                  ),
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
