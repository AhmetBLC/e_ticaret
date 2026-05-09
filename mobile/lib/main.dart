import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'data/datasources/local/session_storage.dart';
import 'data/datasources/remote/api_client.dart';
import 'data/datasources/remote/auth_remote_datasource.dart';
import 'data/datasources/remote/product_remote_datasource.dart';
import 'data/datasources/remote/swap_remote_datasource.dart';
import 'data/datasources/remote/order_remote_datasource.dart';
import 'data/datasources/remote/chat_remote_datasource.dart';
import 'data/datasources/remote/shipment_remote_datasource.dart';
import 'data/datasources/remote/work_order_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/product_repository_impl.dart';
import 'data/repositories/swap_repository_impl.dart';
import 'data/repositories/order_repository_impl.dart';
import 'data/repositories/shipment_repository_impl.dart';
import 'data/repositories/work_order_repository_impl.dart';
import 'presentation/providers/chat_provider.dart';
import 'domain/repositories/chat_repository.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/order_repository.dart';
import 'domain/repositories/shipment_repository.dart';
import 'domain/repositories/product_repository.dart';
import 'domain/repositories/swap_repository.dart';
import 'domain/repositories/work_order_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/product_catalog_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final sessionStorage = SessionStorage(prefs);

  final apiClient = ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    sessionStorage: sessionStorage,
  );

  final authRemote = AuthRemoteDatasource(apiClient);
  final productRemote = ProductRemoteDatasource(apiClient);
  final swapRemote = SwapRemoteDatasource(apiClient);
  final orderRemote = OrderRemoteDatasource(apiClient);
  final chatRemote = ChatRemoteDatasource(apiClient);
  final shipmentRemote = ShipmentRemoteDatasource(apiClient);
  final workOrderRemote = WorkOrderRemoteDatasource(apiClient);

  final authRepository = AuthRepositoryImpl(
    remote: authRemote,
    sessionStorage: sessionStorage,
  );
  final productRepository = ProductRepositoryImpl(productRemote);
  final swapRepository = SwapRepositoryImpl(swapRemote);
  final orderRepository = OrderRepositoryImpl(orderRemote);
  final shipmentRepository = ShipmentRepositoryImpl(shipmentRemote);
  final chatRepository = ChatRepositoryImpl(chatRemote);
  final workOrderRepository = WorkOrderRepositoryImpl(workOrderRemote);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<ProductRepository>.value(value: productRepository),
        Provider<SwapRepository>.value(value: swapRepository),
        Provider<OrderRepository>.value(value: orderRepository),
        Provider<ShipmentRepository>.value(value: shipmentRepository),
        Provider<ChatRepository>.value(value: chatRepository),
        Provider<WorkOrderRepository>.value(value: workOrderRepository),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repository: authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductCatalogProvider(productRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(chatRepository),
        ),
      ],
      child: const EticaretApp(),
    ),
  );
}
