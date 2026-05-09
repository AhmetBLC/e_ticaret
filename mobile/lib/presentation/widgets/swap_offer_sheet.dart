import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/network/error_mapper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/product_model.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/swap_repository.dart';
import 'app_state_views.dart';

class SwapOfferSheet extends StatefulWidget {
  const SwapOfferSheet({
    super.key,
    required this.requestedProductId,
    required this.requestedTitle,
    required this.requestedPrice,
  });

  final String requestedProductId;
  final String requestedTitle;
  final double requestedPrice;

  @override
  State<SwapOfferSheet> createState() => _SwapOfferSheetState();
}

class _SwapOfferSheetState extends State<SwapOfferSheet> {
  late Future<List<ProductModel>> _myProductsFuture;
  ProductModel? _selectedProduct;
  final _messageController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _myProductsFuture = _loadMyProducts();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<List<ProductModel>> _loadMyProducts() async {
    final res = await context.read<ProductRepository>().getMyProducts(
          page: 1,
          limit: 100,
        );
    return res.products;
  }

  Future<void> _submit() async {
    if (_selectedProduct == null) return;
    setState(() => _submitting = true);
    try {
      final repo = context.read<SwapRepository>();
      await repo.createSwap(
        productOfferedId: _selectedProduct!.id,
        productRequestedId: widget.requestedProductId,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Takas Teklifi',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Requested Product summary
                  Text(
                    'İstenen Ürün',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.requestedTitle,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${widget.requestedPrice.toStringAsFixed(0)} ₺',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: AppColors.brand,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Text(
                    'Ne teklif ediyorsun?',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  
                  // Product selection
                  FutureBuilder<List<ProductModel>>(
                    future: _myProductsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(color: AppColors.accent),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return AppErrorState(message: userFacingErrorMessage(snapshot.error!));
                      }
                      final products = snapshot.data!;
                      if (products.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 32),
                                const SizedBox(height: 12),
                                Text(
                                  'Yayında aktif ilanınız bulunmuyor.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: theme.colorScheme.onSurface),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: products.length,
                          itemBuilder: (context, i) {
                            final p = products[i];
                            final isSelected = _selectedProduct?.id == p.id;
                            final hasImage = p.imageUrl != null;
                            
                            return GestureDetector(
                              onTap: () => setState(() => _selectedProduct = p),
                              child: Container(
                                width: 140,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? AppColors.accent : (isDark ? AppColors.darkDivider : const Color(0xFFE8E8E8)),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: AppColors.accent.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ] : null,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          if (hasImage)
                                            Image.network(p.imageUrl!, fit: BoxFit.cover)
                                          else
                                            Container(
                                              color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                                              child: Icon(Icons.image_outlined, color: theme.colorScheme.onSurfaceVariant),
                                            ),
                                          if (isSelected)
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: AppColors.accent,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.check, color: Colors.white, size: 14),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.title,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${p.displayPrice.toStringAsFixed(0)} ₺',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.accent,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  
                  if (_selectedProduct != null) ...[
                    const SizedBox(height: 24),
                    Builder(
                      builder: (context) {
                        final diff = _selectedProduct!.price - widget.requestedPrice;
                        Color bg = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;
                        Color textC = theme.colorScheme.onSurface;
                        String msg = 'Başabaş takas.';
                        
                        if (diff > 0) {
                          bg = AppColors.success.withOpacity(0.1);
                          textC = AppColors.success;
                          msg = 'Karşı taraf size ${diff.toStringAsFixed(0)} ₺ ödemelidir.';
                        } else if (diff < 0) {
                          bg = AppColors.warning.withOpacity(0.1);
                          textC = AppColors.warning;
                          msg = 'Sizin karşı tarafa ${diff.abs().toStringAsFixed(0)} ₺ ödemeniz gerekir.';
                        }

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: textC.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: textC),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  msg,
                                  style: TextStyle(color: textC, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 24),
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Mesajınız (Opsiyonel)',
                      hintText: 'Takas düşünür müsünüz?',
                    ),
                    maxLines: 3,
                  ),
                  
                  const SizedBox(height: 32),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: (_submitting || _selectedProduct == null) ? null : AppColors.brandGradient,
                      color: (_submitting || _selectedProduct == null) ? Colors.grey : null,
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                      boxShadow: (_submitting || _selectedProduct == null) ? null : [
                        BoxShadow(
                          color: AppColors.brand.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                        onTap: (_submitting || _selectedProduct == null) ? null : _submit,
                        child: Center(
                          child: _submitting
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  'Teklif Gönder',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),
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
