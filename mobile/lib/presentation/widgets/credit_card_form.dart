import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class CreditCardFormData {
  const CreditCardFormData({required this.lastFour, required this.brand});
  final String lastFour;
  final String brand;
}

class CreditCardForm extends StatefulWidget {
  const CreditCardForm({super.key});

  @override
  State<CreditCardForm> createState() => CreditCardFormState();
}

class CreditCardFormState extends State<CreditCardForm> {
  final _cardNumberController = TextEditingController();
  final _cardBrandController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardBrandController.dispose();
    super.dispose();
  }

  CreditCardFormData? validateAndGet() {
    final number = _cardNumberController.text.trim();
    final brand = _cardBrandController.text.trim();

    if (number.length < 16) return null;
    if (brand.isEmpty) return null;

    return CreditCardFormData(
      lastFour: number.substring(number.length - 4),
      brand: brand,
    );
  }

  String _getFormattedCardNumber() {
    String text = _cardNumberController.text.replaceAll(' ', '');
    if (text.isEmpty) return '**** **** **** ****';
    
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) formatted += ' ';
      formatted += text[i];
    }
    
    // Fill remaining with *
    int remaining = 16 - text.length;
    for (int i = 0; i < remaining; i++) {
      int totalLen = text.length + i;
      if (totalLen > 0 && totalLen % 4 == 0) formatted += ' ';
      formatted += '*';
    }
    
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.lock_rounded, size: 16, color: AppColors.success),
            const SizedBox(width: 8),
            Text(
              'Güvenli Ödeme',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Simüle edilmiş kart görseli
        Container(
          height: 160,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isDark ? AppColors.darkCardGradient : const LinearGradient(
              colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.contactless_rounded, color: Colors.white70, size: 28),
                  Text(
                    'KREDİ KARTI',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getFormattedCardNumber(),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 19, // Biraz küçülttüm ki sığsın
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'GÜVENLİ TAKAS / ALIŞVERİŞ',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        TextFormField(
          controller: _cardNumberController,
          decoration: InputDecoration(
            labelText: 'Kart Numarası',
            hintText: '16 haneli kart numarası',
            prefixIcon: Icon(Icons.credit_card_rounded, color: AppColors.brand.withOpacity(0.7)),
          ),
          keyboardType: TextInputType.number,
          maxLength: 16,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _cardBrandController,
          decoration: InputDecoration(
            labelText: 'Kart Markası (örn. Visa, Mastercard)',
            prefixIcon: Icon(Icons.branding_watermark_rounded, color: AppColors.brand.withOpacity(0.7)),
          ),
        ),
      ],
    );
  }
}
