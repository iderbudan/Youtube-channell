import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../state/cart_provider.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';

/// Доод навигацтай үндсэн бүтэц: Дэлгүүр / Сагс / Захиалга.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static void goTo(BuildContext context, int tab) =>
      context.findAncestorStateOfType<_AppShellState>()?.select(tab);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void select(int i) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartProvider, int>((c) => c.count);
    return Scaffold(
      body: IndexedStack(index: _index, children: const [
        HomeScreen(),
        CartScreen(),
        OrdersScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: select,
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Дэлгүүр'),
          NavigationDestination(
              icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.shopping_bag_outlined)),
              selectedIcon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.shopping_bag)),
              label: 'Сагс'),
          const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Захиалга'),
        ],
      ),
    );
  }
}
