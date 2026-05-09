import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../domain/repositories/shipment_repository.dart';
import '../../data/models/shipment_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/status_badges.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final _codeController = TextEditingController();
  ShipmentModel? _shipment;
  bool _loading = false;
  String? _error;

  Future<void> _track() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = context.read<ShipmentRepository>();
      final shipment = await repo.trackShipment(code);
      
      setState(() {
        _loading = false;
        _shipment = shipment;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _shipment = null;
        _loading = false;
        _error = 'Gönderi bulunamadı. Lütfen takip kodunu kontrol edin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Sipariş Takibi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_shipping_rounded, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kargon Nerede?',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sana verilen takip kodunu girerek kargonu izle.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Takip Kodu',
                hintText: 'TRK-XXXX-XXXX',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.brand.withOpacity(0.7)),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 24),
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: _loading ? null : AppColors.brandGradient,
                color: _loading ? Colors.grey : null,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                boxShadow: _loading
                    ? null
                    : [
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
                  onTap: _loading ? null : _track,
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Sorgula',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_shipment != null) ...[
              const SizedBox(height: 40),
              Row(
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
                    'Kargo Durumu',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  ShipmentStatusBadge(status: _shipment!.status),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(
                    color: isDark ? AppColors.darkDivider : const Color(0xFFE8E8E8),
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _infoRow(
                        context,
                        Icons.inventory_2_rounded,
                        'Ürün',
                        _shipment!.productTitle ?? 'Bilinmeyen Ürün',
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB), height: 1),
                      ),
                      _infoRow(
                        context,
                        Icons.storefront_rounded,
                        'Taşıyıcı',
                        _shipment!.carrier,
                      ),
                      if (_shipment!.estimatedDelivery != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB), height: 1),
                        ),
                        _infoRow(
                          context,
                          Icons.event_available_rounded,
                          'Tahmini Gönderim',
                          _shipment!.estimatedDelivery!.toString().split(' ')[0],
                          isHighlighted: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value, {bool isHighlighted = false}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isHighlighted ? AppColors.brand.withOpacity(0.1) : (theme.brightness == Brightness.dark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: isHighlighted ? AppColors.brand : theme.colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isHighlighted ? AppColors.brand : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
