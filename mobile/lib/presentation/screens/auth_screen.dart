import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/responsive_wrapper.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPassword = TextEditingController();
  final _formLogin = GlobalKey<FormState>();
  final _formReg = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _regEmail.dispose();
    _regPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ResponsiveWrapper(
        maxWidth: 500,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Brand Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.brandGradient.createShader(bounds),
                child: Text(
                  'TakasApp',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'İkinci el, ilk kalite',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Tab Selector
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brand.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Giriş Yap'),
                    Tab(text: 'Kayıt Ol'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tab Content
              SizedBox(
                height: 380,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLoginTab(auth, theme, isDark),
                    _buildRegisterTab(auth, theme, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab(AuthProvider auth, ThemeData theme, bool isDark) {
    return Form(
      key: _formLogin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _loginEmail,
            decoration: InputDecoration(
              labelText: 'E-posta',
              prefixIcon: Icon(Icons.mail_outline_rounded, color: AppColors.brand.withOpacity(0.7)),
            ),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Gerekli';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPassword,
            decoration: InputDecoration(
              labelText: 'Şifre',
              prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.brand.withOpacity(0.7)),
            ),
            obscureText: true,
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Gerekli';
              }
              return null;
            },
          ),
          if (auth.error != null) ...[
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
                auth.error ?? 'Bir hata oluştu',
                style: TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: auth.submitting ? null : AppColors.brandGradient,
              color: auth.submitting ? Colors.grey : null,
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              boxShadow: auth.submitting
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
                onTap: auth.submitting
                    ? null
                    : () async {
                        auth.clearError();
                        if (!(_formLogin.currentState?.validate() ?? false)) {
                          return;
                        }
                        final ok = await auth.login(
                          _loginEmail.text.trim(),
                          _loginPassword.text,
                        );
                        if (ok && mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                child: Center(
                  child: auth.submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Giriş Yap',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/order-tracking');
            },
            icon: const Icon(Icons.local_shipping_outlined, size: 18),
            label: const Text('Ziyaretçi Sipariş Takibi'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterTab(AuthProvider auth, ThemeData theme, bool isDark) {
    return Form(
      key: _formReg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _regEmail,
            decoration: InputDecoration(
              labelText: 'E-posta',
              prefixIcon: Icon(Icons.mail_outline_rounded, color: AppColors.brand.withOpacity(0.7)),
            ),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Gerekli';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _regPassword,
            decoration: InputDecoration(
              labelText: 'Şifre (en az 8 karakter)',
              prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.brand.withOpacity(0.7)),
            ),
            obscureText: true,
            validator: (v) {
              if (v == null || v.length < 8) {
                return 'En az 8 karakter';
              }
              return null;
            },
          ),
          if (auth.error != null) ...[
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
                auth.error ?? 'Bir hata oluştu',
                style: TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: auth.submitting ? null : AppColors.brandGradient,
              color: auth.submitting ? Colors.grey : null,
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              boxShadow: auth.submitting
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
                onTap: auth.submitting
                    ? null
                    : () async {
                        auth.clearError();
                        if (!(_formReg.currentState?.validate() ?? false)) {
                          return;
                        }
                        final ok = await auth.register(
                          _regEmail.text.trim(),
                          _regPassword.text,
                        );
                        if (ok && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Hesap oluşturuldu. Giriş yapabilirsiniz.',
                              ),
                            ),
                          );
                          _tabController.animateTo(0);
                        }
                      },
                child: Center(
                  child: auth.submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Hesap Oluştur',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
