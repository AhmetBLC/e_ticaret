import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/user_roles.dart';
import '../../core/network/error_mapper.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/pagination_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/work_order_model.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/shipment_repository.dart';
import '../../domain/repositories/work_order_repository.dart';
import '../../data/models/shipment_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_state_views.dart';
import '../widgets/escrow_info_row.dart';
import '../widgets/status_badges.dart';
import 'product_detail_screen.dart';

/// Simple admin area: dashboard, workshop queue (swap approvals), catalog overview.
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.user?.role == UserRoles.admin;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yönetim')),
        body: AppRefreshableScrollable(
          child: AppEmptyState(
            icon: Icons.lock_outline,
            title: 'Yetkisiz',
            subtitle: 'Bu alan yalnızca yöneticiler içindir.',
            onAction: () => Navigator.of(context).pop(),
            actionLabel: 'Geri dön',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetim paneli'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Özet'),
            Tab(icon: Icon(Icons.build_circle_outlined), text: 'Atölye'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Ürünler'),
            Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Kargo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DashboardTab(),
          _WorkshopTab(),
          _ProductsTab(),
          _CargoTab(),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  late Future<_DashStats> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.microtask(() => _load());
  }

  Future<_DashStats> _load() async {
    final wo = context.read<WorkOrderRepository>();
    final pr = context.read<ProductRepository>();
    final woData = await wo.listWorkOrders(page: 1, limit: 100);
    final pending =
        woData.workOrders.where((w) => w.isPending).length;
    final products = await pr.getProducts(page: 1, limit: 1);
    final total = products.pagination?.total ?? products.products.length;
    return _DashStats(
      pendingWorkOrders: pending,
      totalProducts: total,
    );
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _refresh();
        await _future;
      },
      child: FutureBuilder<_DashStats>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingBody(message: 'Özet yükleniyor…');
          }
          if (snapshot.hasError) {
            return AppRefreshableScrollable(
              child: AppErrorState(
                message: userFacingErrorMessage(snapshot.error!),
                onRetry: _refresh,
              ),
            );
          }
          final s = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
            children: [
              Text(
                'Özet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              _StatCard(
                icon: Icons.build_circle_outlined,
                label: 'Bekleyen atölye işi',
                value: '${s.pendingWorkOrders}',
                subtitle: 'Onay veya red bekleyen takaslar',
              ),
              const SizedBox(height: AppSpacing.sm),
              _StatCard(
                icon: Icons.inventory_2_outlined,
                label: 'Toplam ürün',
                value: '${s.totalProducts}',
                subtitle: 'Pazarda listelenen ilanlar',
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Atölye sekmesinden takasları onaylayın veya reddedin; '
                'Ürünler sekmesinden tüm ilanları görüntüleyin.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashStats {
  const _DashStats({
    required this.pendingWorkOrders,
    required this.totalProducts,
  });

  final int pendingWorkOrders;
  final int totalProducts;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: 40, color: cs.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkshopTab extends StatefulWidget {
  const _WorkshopTab();

  @override
  State<_WorkshopTab> createState() => _WorkshopTabState();
}

class _WorkshopTabState extends State<_WorkshopTab> {
  late Future<
      ({
        List<WorkOrderModel> workOrders,
        PaginationModel? pagination
      })> _future;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _future = Future.microtask(() => _load());
  }

  Future<
      ({
        List<WorkOrderModel> workOrders,
        PaginationModel? pagination
      })> _load() async {
    final repo = context.read<WorkOrderRepository>();
    return repo.listWorkOrders(page: 1, limit: 100);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _approve(WorkOrderModel wo) async {
    setState(() => _busy.add(wo.id));
    try {
      final result = await context.read<WorkOrderRepository>().approve(wo.id);
      if (!mounted) {
        return;
      }
      var msg = 'Onaylandı. Ürün sahipleri güncellendi.';
      final e = result.escrow;
      if (e != null && e.isReleased) {
        msg +=
            ' Fiyat farkı emanetten çıkarıldı (${e.amount.toStringAsFixed(2)}).';
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
        setState(() => _busy.remove(wo.id));
      }
    }
  }

  Future<void> _reject(WorkOrderModel wo) async {
    setState(() => _busy.add(wo.id));
    try {
      final result = await context.read<WorkOrderRepository>().reject(wo.id);
      if (!mounted) {
        return;
      }
      var msg = 'Takas reddedildi, ürünler tekrar satışa açıldı.';
      final e = result.escrow;
      if (e != null && e.isRefunded) {
        msg +=
            ' Fiyat farkı iade edildi (${e.amount.toStringAsFixed(2)}).';
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
        setState(() => _busy.remove(wo.id));
      }
    }
  }

  Future<void> _initiateCargo(WorkOrderModel wo) async {
    setState(() => _busy.add(wo.id));
    try {
      await context.read<ShipmentRepository>().initiateShipment(wo.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kargo kodları başarıyla oluşturuldu!')),
        );
      }
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy.remove(wo.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _refresh();
        await _future;
      },
      child: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingBody(message: 'İş emirleri yükleniyor…');
          }
          if (snapshot.hasError) {
            return AppRefreshableScrollable(
              child: AppErrorState(
                message: userFacingErrorMessage(snapshot.error!),
                onRetry: _refresh,
              ),
            );
          }
          final list = snapshot.data!.workOrders;
          final pending =
              list.where((w) => w.isPending).toList(growable: false);
          if (pending.isEmpty) {
            return AppRefreshableScrollable(
              child: const AppEmptyState(
                icon: Icons.check_circle_outline,
                title: 'Bekleyen iş yok',
                subtitle: 'Yeni takas onayları burada görünecek.',
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
            itemCount: pending.length,
            itemBuilder: (context, i) {
              final wo = pending[i];
              final swap = wo.swap;
              final order = wo.order;
              final busy = _busy.contains(wo.id);

              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.listGap),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'İş emri ${wo.id.substring(0, 8)}…',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          WorkOrderStatusBadge(status: wo.status),
                          if (swap != null) ...[
                            const Chip(label: Text('Takas'), visualDensity: VisualDensity.compact),
                            SwapStatusBadge(status: swap.status),
                          ] else if (order != null) ...[
                            const Chip(label: Text('Direkt Satış'), visualDensity: VisualDensity.compact),
                            Text('Sipariş: ${order.id.substring(0, 8)}…'),
                          ],
                        ],
                      ),
                      if (wo.escrow != null) ...[
                        const SizedBox(height: 10),
                        EscrowInfoRow(escrow: wo.escrow!),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: busy ? null : () => _initiateCargo(wo),
                              child: const Text('Kargo Oluştur'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: busy ? null : () => _approve(wo),
                              child: busy
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Onayla'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: busy ? null : () => _reject(wo),
                              child: const Text('Reddet'),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _ProductsTab extends StatefulWidget {
  const _ProductsTab();

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  late Future<
      ({
        List<ProductModel> products,
        PaginationModel? pagination
      })> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.microtask(() => _load());
  }

  Future<
      ({
        List<ProductModel> products,
        PaginationModel? pagination
      })> _load() async {
    return context.read<ProductRepository>().getProducts(page: 1, limit: 100);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _refresh();
        await _future;
      },
      child: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingBody(message: 'Ürünler yükleniyor…');
          }
          if (snapshot.hasError) {
            return AppRefreshableScrollable(
              child: AppErrorState(
                message: userFacingErrorMessage(snapshot.error!),
                onRetry: _refresh,
              ),
            );
          }
          final products = snapshot.data!.products;
          if (products.isEmpty) {
            return AppRefreshableScrollable(
              child: const AppEmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Kayıtlı ilan yok',
                subtitle: 'Pazarda henüz listelenmiş ürün bulunmuyor.',
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
            itemCount: products.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, i) {
              final p = products[i];
              return Card(
                child: ListTile(
                  title: Text(
                    p.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${p.displayPrice.toStringAsFixed(2)} ₺ · '
                    '${p.isAvailable ? 'Müsait' : 'Kapalı'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ProductDetailScreen(productId: p.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class _CargoTab extends StatefulWidget {
  const _CargoTab();

  @override
  State<_CargoTab> createState() => _CargoTabState();
}

class _CargoTabState extends State<_CargoTab> {
  late Future<List<ShipmentModel>> _future;
  bool _busy = false;

  final Map<String, ({String label, String next})> _statusActions = {
    'LABEL_CREATED': (label: 'Kurye Teslim Aldı', next: 'PICKED_UP'),
    'PICKED_UP': (label: 'Yola Çıktı', next: 'IN_TRANSIT'),
    'IN_TRANSIT': (label: 'Dağıtıma Çıktı', next: 'OUT_FOR_DELIVERY'),
    'OUT_FOR_DELIVERY': (label: 'Teslim Edildi', next: 'DELIVERED'),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<ShipmentRepository>().getAllShipments();
  }

  void _refresh() {
    setState(_load);
  }

  Future<void> _advanceStatus(String id, String nextStatus) async {
    setState(() => _busy = true);
    try {
      final repo = context.read<ShipmentRepository>();
      await repo.advanceStatus(id, nextStatus);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _simulateProgress(String id) async {
    setState(() => _busy = true);
    try {
      await context.read<ShipmentRepository>().simulateDelivery(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kargo süreci simüle edildi.')),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _refresh();
        await _future;
      },
      child: FutureBuilder<List<ShipmentModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingBody(message: 'Kargolar yükleniyor…');
          }
          if (snapshot.hasError) {
            return AppRefreshableScrollable(
              child: AppErrorState(
                message: userFacingErrorMessage(snapshot.error!),
                onRetry: _refresh,
              ),
            );
          }
          final list = snapshot.data!;
          if (list.isEmpty) {
            return AppRefreshableScrollable(
              child: const AppEmptyState(
                icon: Icons.local_shipping_outlined,
                title: 'Aktif kargo yok',
                subtitle: 'Sipariş edildikten sonra kargo süreci burada görünür.',
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final s = list[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.productTitle ?? 'İsimsiz Ürün',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${s.senderName ?? '...'} → ${s.receiverName ?? '...'}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          ShipmentStatusBadge(status: s.status),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Takip No', style: Theme.of(context).textTheme.labelSmall),
                              SelectableText(s.trackingNumber, style: const TextStyle(fontFamily: 'monospace')),
                            ],
                          ),
                          Text(s.carrier, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (_statusActions.containsKey(s.status))
                            Expanded(
                              flex: 2,
                              child: FilledButton(
                                onPressed: _busy ? null : () => _advanceStatus(s.id, _statusActions[s.status]!.next),
                                child: Text(_statusActions[s.status]!.label),
                              ),
                            )
                          else
                            const Expanded(flex: 2, child: SizedBox.shrink()),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              onPressed: () => _showDetail(s),
                              child: const Text('Detay'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: _busy ? null : () => _simulateProgress(s.id),
                          icon: const Icon(Icons.fast_forward, size: 16),
                          label: const Text('Otomatik Simüle Et (Hızlı)', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetail(ShipmentModel s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kargo Detayı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Ürün:', s.productTitle ?? 'Bilinmiyor'),
            _detailRow('Gönderici:', s.senderName ?? 'Bilinmiyor'),
            _detailRow('Alıcı:', s.receiverName ?? 'Bilinmiyor'),
            _detailRow('Taşıyıcı:', s.carrier),
            _detailRow('Durum:', s.status),
            _detailRow('Takip No:', s.trackingNumber),
            if (s.estimatedDelivery != null)
              _detailRow('Tahmini Varış:', s.estimatedDelivery!.toLocal().toString().split('.').first),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
