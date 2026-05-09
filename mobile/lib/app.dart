import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/navigation/app_route_observer.dart';
import 'core/navigation/app_routes.dart';
import 'data/datasources/remote/api_client.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/account_screen.dart';
import 'presentation/screens/create_listing_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/orders_screen.dart';
import 'presentation/screens/swaps_screen.dart';
import 'presentation/screens/admin_panel_screen.dart';
import 'presentation/screens/conversations_screen.dart';
import 'presentation/screens/order_tracking_screen.dart';
import 'presentation/widgets/app_state_views.dart';
import 'presentation/widgets/auth_required.dart';

class EticaretApp extends StatelessWidget {
  const EticaretApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TakasApp',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [appRouteObserver],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const _AuthGate(),
      routes: {
        AppRoutes.account: (_) => const AuthRequired(
              child: AccountScreen(),
            ),
        AppRoutes.createListing: (_) => const AuthRequired(
              child: CreateListingScreen(),
            ),
        AppRoutes.swaps: (_) => const AuthRequired(
              child: SwapsScreen(),
            ),
        AppRoutes.orders: (_) => const AuthRequired(
              child: OrdersScreen(),
            ),
        AppRoutes.admin: (_) => const AuthRequired(
              child: AdminPanelScreen(),
            ),
        AppRoutes.conversations: (_) => const AuthRequired(
              child: ConversationsScreen(),
            ),
        AppRoutes.orderTracking: (_) => const OrderTrackingScreen(),
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _registeredSessionHandler = false;

  void _ensureSessionExpiryHook(BuildContext context) {
    if (_registeredSessionHandler) {
      return;
    }
    _registeredSessionHandler = true;
    final api = context.read<ApiClient>();
    final auth = context.read<AuthProvider>();
    api.setOnSessionExpired(() async {
      await auth.logout();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Oturum süresi doldu veya geçersiz. Tekrar giriş yapın.'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.initializing) {
      return const Scaffold(
        body: AppLoadingBody(message: 'Oturum kontrol ediliyor…'),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        _ensureSessionExpiryHook(context);
      }
    });
    return const HomeScreen();
  }
}
