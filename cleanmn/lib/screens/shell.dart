import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/cart_provider.dart';
import '../state/catalog_provider.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';

/// Доод навигацтай үндсэн бүтэц: Дэлгүүр / Сагс / Захиалга + зүүн талын цэс.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static AppShellState? of(BuildContext context) => context.findAncestorStateOfType<AppShellState>();

  static void goTo(BuildContext context, int tab) => of(context)?.select(tab);

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  int _index = 0;
  final _homeScroll = ScrollController();
  final _search = TextEditingController();

  @override
  void dispose() {
    _homeScroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void select(int i) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _index = i);
  }

  /// Нүүр хуудас: шүүлтүүр, хайлтыг цэвэрлээд дээш гүйлгэнэ.
  void goHome() {
    context.read<CatalogProvider>().resetFilters();
    _search.clear();
    _showStoreTop();
  }

  /// Цэснээс ангилал сонгох.
  void openCategory(ProductCategory c) {
    final catalog = context.read<CatalogProvider>()..resetFilters();
    catalog.setCategory(c);
    _search.clear();
    _showStoreTop();
  }

  void _showStoreTop() {
    Navigator.of(context).popUntil((r) => r.isFirst);
    select(0);
    if (_homeScroll.hasClients) {
      _homeScroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartProvider, int>((c) => c.count);
    return Scaffold(
      drawer: _MenuDrawer(shell: this),
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(scroll: _homeScroll, search: _search),
          const CartScreen(),
          const OrdersScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => i == 0 && _index == 0 ? goHome() : select(i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Дэлгүүр',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              child: const Icon(Icons.shopping_bag),
            ),
            label: 'Сагс',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Захиалга',
          ),
        ],
      ),
    );
  }
}

/// Зүүн талын цэс (☰): нүүр хуудас, дугаарласан ангилал, сагс, захиалга.
class _MenuDrawer extends StatelessWidget {
  const _MenuDrawer({required this.shell});
  final AppShellState shell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final catalog = context.watch<CatalogProvider>();

    void close(VoidCallback action) {
      Navigator.of(context).pop();
      action();
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            InkWell(
              onTap: () => close(shell.goHome),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Clean',
                            style: TextStyle(color: scheme.onSurface),
                          ),
                          TextSpan(
                            text: 'MN',
                            style: TextStyle(color: scheme.primary),
                          ),
                        ],
                      ),
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Цэвэрлэгээний бараа гэрт тань',
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
            _tile(
              context,
              icon: Icons.home_outlined,
              text: 'Нүүр хуудас',
              selected: catalog.isHome,
              onTap: () => close(shell.goHome),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 20, 8),
              child: Text(
                'АНГИЛАЛ',
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.2,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final (i, c) in ProductCategory.values.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: ListTile(
                  key: Key('menu-${c.id}'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  selected: catalog.category == c,
                  selectedTileColor: scheme.primaryContainer,
                  leading: CircleAvatar(
                    radius: 15,
                    backgroundColor: catalog.category == c ? scheme.primary : scheme.primaryContainer,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: catalog.category == c ? scheme.onPrimary : scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  title: Text(c.label),
                  trailing: Text(
                    '${catalog.all.where((p) => p.category == c).length}',
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  onTap: () => close(() => shell.openCategory(c)),
                ),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(indent: 16, endIndent: 16),
            ),
            _tile(
              context,
              icon: Icons.shopping_bag_outlined,
              text: 'Сагс',
              onTap: () => close(() => shell.select(1)),
            ),
            _tile(
              context,
              icon: Icons.receipt_long_outlined,
              text: 'Миний захиалга',
              onTap: () => close(() => shell.select(2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool selected = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    child: ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
      leading: Icon(icon),
      title: Text(text),
      onTap: onTap,
    ),
  );
}
