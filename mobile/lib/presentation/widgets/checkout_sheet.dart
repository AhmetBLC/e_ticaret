import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/network/error_mapper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/product_model.dart';
import '../../domain/repositories/product_repository.dart';
import 'credit_card_form.dart';

class CheckoutSheet extends StatefulWidget {
  const CheckoutSheet({
    super.key,
    required this.productId,
    required this.title,
    required this.price,
    this.variantId,
  });

  final String productId;
  final String title;
  final double price;
  final String? variantId;

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  final _couponController = TextEditingController();
  final _addressController = TextEditingController();
  final _cardFormKey = GlobalKey<CreditCardFormState>();

  bool _submitting = false;

  @override
  void dispose() {
    _couponController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cardData = _cardFormKey.currentState?.validateAndGet();
    if (cardData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kredi kartı bilgilerini eksiksiz girin')),
      );
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen teslimat adresi belirtin')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = context.read<ProductRepository>();
      await repo.checkout(
        items: [
          {
            'product_id': widget.productId,
            if (widget.variantId != null) 'variant_id': widget.variantId,
            'quantity': 1,
          }
        ],
        couponCode: _couponController.text.trim().isEmpty ? null : _couponController.text.trim(),
        cardLastFour: cardData.lastFour,
        cardBrand: cardData.brand,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Güvenli Satın Al',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            
            // Order summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.shopping_bag_rounded, color: AppColors.brand, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ödenecek Tutar',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${widget.price.toStringAsFixed(0)} ₺',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.brand,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Teslimat Adresi',
                hintText: 'Açık adres, ilçe ve il',
                prefixIcon: Icon(Icons.location_on_rounded, color: theme.colorScheme.onSurfaceVariant),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _couponController,
              decoration: InputDecoration(
                labelText: 'Kupon Kodu (Opsiyonel)',
                prefixIcon: Icon(Icons.local_offer_rounded, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            
            CreditCardForm(key: _cardFormKey),
            const SizedBox(height: 32),
            
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: _submitting ? null : AppColors.brandGradient,
                color: _submitting ? Colors.grey : null,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                boxShadow: _submitting ? null : [
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
                  onTap: _submitting ? null : _submit,
                  child: Center(
                    child: _submitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Güvenli Ödeme Yap',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
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
      ),
    );
  }
}
