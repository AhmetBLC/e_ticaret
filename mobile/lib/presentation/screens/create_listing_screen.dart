import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/network/error_mapper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/repositories/product_repository.dart';
import '../providers/product_catalog_provider.dart';

class _VariantInput {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
  }
}

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  
  List<XFile> _pickedImages = [];
  String? _selectedCity;
  String? _selectedDistrict;
  bool _submitting = false;
  String? _error;

  final List<_VariantInput> _variants = [];

  final Map<String, List<String>> _locations = {
    'İstanbul': ['Ataşehir', 'Beşiktaş', 'Kadıköy', 'Şişli', 'Üsküdar'],
    'Ankara': ['Çankaya', 'Keçiören', 'Mamak', 'Yenimahalle'],
    'İzmir': ['Bornova', 'Çiğli', 'Karşıyaka', 'Konak'],
    'Bursa': ['Nilüfer', 'Osmangazi', 'Yıldırım'],
    'Antalya': ['Konyaaltı', 'Muratpaşa'],
  };

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    for (var v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      imageQuality: 80,
    );
    if (images.isNotEmpty) {
      setState(() {
        _pickedImages = images;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
    });
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final price = double.tryParse(_price.text.replaceAll(',', '.'));
    if (price == null || price < 0) {
      setState(() => _error = 'Geçerli bir fiyat girin.');
      return;
    }
    if (_selectedCity == null) {
      setState(() => _error = 'Lütfen bir şehir seçin.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = context.read<ProductRepository>();
      
      String? uploadedMainUrl;
      List<String> additionalImages = [];

      if (_pickedImages.isNotEmpty) {
        // First image is the main image
        uploadedMainUrl = await repo.uploadFile(_pickedImages[0]);
        
        // Others are additional
        if (_pickedImages.length > 1) {
          for (int i = 1; i < _pickedImages.length; i++) {
            final url = await repo.uploadFile(_pickedImages[i]);
            additionalImages.add(url);
          }
        }
      }

      await repo.createListing(
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        price: price,
        imageUrl: uploadedMainUrl,
        additionalImages: additionalImages,
        city: _selectedCity,
        district: _selectedDistrict,
        variants: _variants.map((v) => {
          'name': v.nameController.text.trim(),
          'price_override': double.tryParse(v.priceController.text.trim()),
          'stock_quantity': int.tryParse(v.stockController.text.trim()) ?? 0,
        }).toList(),
      );
      if (!mounted) return;
      await context.read<ProductCatalogProvider>().refresh();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = userFacingErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni İlan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            // ── Image Section ─────────────────────────────
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(
                    color: AppColors.brand.withOpacity(0.3),
                    width: 1.5,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: _pickedImages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppColors.brandGradient,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.add_a_photo_rounded, size: 24, color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Fotoğrafları Seç (Max 10)',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'İlk fotoğraf kapak olur',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(10),
                        itemCount: _pickedImages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _pickedImages.length) {
                            return Center(
                              child: Container(
                                width: 60,
                                height: 60,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.brand.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.brand.withOpacity(0.3)),
                                ),
                                child: IconButton(
                                  onPressed: _pickImages,
                                  icon: Icon(Icons.add_rounded, color: AppColors.brand),
                                ),
                              ),
                            );
                          }
                          return Container(
                            width: 110,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: FileImage(File(_pickedImages[index].path)),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Stack(
                              children: [
                                if (index == 0)
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.brandGradient,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Kapak',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _pickedImages.removeAt(index)),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Ne satıyorsun?',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => v == null || v.trim().isEmpty ? 'Gerekli' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Açıklama (isteğe bağlı)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _price,
              decoration: InputDecoration(
                labelText: 'Fiyat (₺)',
                prefixIcon: Icon(Icons.payments_outlined, color: AppColors.brand.withOpacity(0.7)),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v == null || v.trim().isEmpty ? 'Gerekli' : null,
            ),
            const SizedBox(height: 24),
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
                      'Seçenekler',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _variants.add(_VariantInput())),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Ekle'),
                ),
              ],
            ),
            if (_variants.isEmpty)
              Text(
                'Hiç seçenek eklenmedi (Örn: Mavi - L).',
                style: TextStyle(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
              )
            else
              ..._variants.asMap().entries.map((entry) {
                final i = entry.key;
                final v = entry.value;
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightSurfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                      color: isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: v.nameController,
                              decoration: const InputDecoration(labelText: 'Seçenek adı'),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() {
                              _variants[i].dispose();
                              _variants.removeAt(i);
                            }),
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: v.priceController,
                              decoration: const InputDecoration(labelText: 'Ek Fiyat'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: v.stockController,
                              decoration: const InputDecoration(labelText: 'Stok'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 24),
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
                  'Konum Bilgisi',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCity,
              decoration: const InputDecoration(labelText: 'Şehir'),
              items: _locations.keys.map((city) {
                return DropdownMenuItem(value: city, child: Text(city));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCity = val;
                  _selectedDistrict = null;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDistrict,
              decoration: const InputDecoration(labelText: 'İlçe'),
              items: _selectedCity == null
                  ? []
                  : _locations[_selectedCity]!.map((district) {
                       return DropdownMenuItem(value: district, child: Text(district));
                    }).toList(),
              onChanged: (val) {
                setState(() {
                   _selectedDistrict = val;
                });
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: _submitting ? null : AppColors.brandGradient,
                color: _submitting ? Colors.grey : null,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                boxShadow: _submitting
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
                  onTap: _submitting ? null : _submit,
                  child: Center(
                    child: _submitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'İlanı Yayınla',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
