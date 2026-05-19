import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../providers/auth_provider.dart';
import '../screens/auth_screen.dart';
import 'app_state_views.dart';
import 'responsive_wrapper.dart';

/// Wraps a screen that requires an authenticated user. Guests see a login prompt.
class AuthRequired extends StatelessWidget {
  const AuthRequired({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.initializing) {
      return const Scaffold(
        body: AppLoadingBody(message: 'Hesap kontrol ediliyor…'),
      );
    }
    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hesap')),
        body: ResponsiveWrapper(
          maxWidth: 450,
          child: AppRefreshableScrollable(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppEmptyState(
                    icon: Icons.lock_person_outlined,
                    title: 'Giriş gerekli',
                    subtitle: 'Bu sayfayı görmek için oturum açın.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await Navigator.of(context).push<bool>(
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                      },
                      child: const Text('Giriş yap'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Geri dön'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return child;
  }
}
