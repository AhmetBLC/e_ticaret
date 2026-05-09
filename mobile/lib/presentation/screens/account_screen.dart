import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/user_roles.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/repositories/order_repository.dart';
import '../providers/auth_provider.dart';

/// Example **protected** destination: only reachable with a valid session when wrapped in [AuthRequired].
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final user = auth.user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesabım'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: context.read<OrderRepository>().getStats(),
        builder: (context, snapshot) {
          final stats = snapshot.data;
          
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              // ── Profile Card ────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.email,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (user.role != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                user.role!,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.brand),
                  ),
                )
              else if (stats != null) ...[
                // ── Sales Performance ─────────────────────
                _SectionTitle(title: 'Satış Performansım'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatCard(
                      label: 'Toplam Kazanç',
                      value: '${stats['user_earnings'] ?? 0} ₺',
                      icon: Icons.payments_rounded,
                      gradient: AppColors.accentGradient,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Satılan Ürün',
                      value: '${stats['user_sales_count'] ?? 0}',
                      icon: Icons.shopping_basket_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                      ),
                    ),
                  ],
                ),
                
                if (user.role == UserRoles.admin && stats['admin_total_sales'] != null) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  _SectionTitle(title: 'Yönetici Özeti'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatCard(
                        label: 'Brüt Ciro',
                        value: '${stats['admin_total_sales'] ?? 0} ₺',
                        icon: Icons.account_balance_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Sipariş Sayısı',
                        value: '${stats['admin_order_count'] ?? 0}',
                        icon: Icons.receipt_long_rounded,
                        gradient: AppColors.brandGradient,
                      ),
                    ],
                  ),
                ],
              ],

              const SizedBox(height: AppSpacing.xxl),
              _SectionTitle(title: 'İşlemlerim'),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.shopping_bag_rounded,
                title: 'Siparişlerim',
                subtitle: 'Satın aldığım ve sattığım ürünler',
                gradient: AppColors.brandGradient,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.orders),
              ),
              _MenuTile(
                icon: Icons.swap_horiz_rounded,
                title: 'Takas Tekliflerim',
                subtitle: 'Gelen ve giden takas istekleri',
                gradient: AppColors.accentGradient,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.swaps),
              ),
              _MenuTile(
                icon: Icons.chat_rounded,
                title: 'Mesajlarım',
                subtitle: 'Alıcı ve satıcılarla olan görüşmeler',
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                ),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.conversations),
              ),
              if (user.role == UserRoles.admin) ...[
                const SizedBox(height: 16),
                _SectionTitle(title: 'Yönetici'),
                const SizedBox(height: 12),
                _MenuTile(
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Yönetim Paneli',
                  subtitle: 'Atölye kuyruğu ve platform yönetimi',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFEC4899)],
                  ),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.admin),
                ),
              ],

              const SizedBox(height: AppSpacing.xxxl),
              // ── Logout Button ───────────────────────────
              Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    onTap: () async {
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Çıkış Yap',
                          style: GoogleFonts.poppins(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
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
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final LinearGradient gradient;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                color: isDark ? AppColors.darkDivider.withOpacity(0.5) : const Color(0xFFE8E8E8),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: isDark ? AppColors.darkDivider.withOpacity(0.5) : const Color(0xFFE8E8E8),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
