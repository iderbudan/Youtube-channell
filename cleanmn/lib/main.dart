import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'screens/shell.dart';
import 'services/api_service.dart';
import 'services/local_store.dart';
import 'services/mock_api_service.dart';
import 'state/cart_provider.dart';
import 'state/catalog_provider.dart';
import 'state/orders_provider.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalStore.open();
  final ApiService api =
      AppConfig.useMock ? MockApiService() : HttpApiService(AppConfig.apiBaseUrl);
  runApp(CleanMNApp(api: api, store: store));
}

class CleanMNApp extends StatelessWidget {
  const CleanMNApp({super.key, required this.api, this.store});

  final ApiService api;
  final LocalStore? store;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CatalogProvider(api)..load()),
        ChangeNotifierProvider(create: (_) => CartProvider(store)),
        ChangeNotifierProvider(create: (_) => OrdersProvider(api, store)),
      ],
      child: MaterialApp(
        title: 'CleanMN',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const AppShell(),
      ),
    );
  }
}
