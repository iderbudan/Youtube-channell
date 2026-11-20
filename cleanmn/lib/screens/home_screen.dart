import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/product.dart';
import '../state/catalog_provider.dart';
import '../utils/format.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final theme = Theme.of(context);
    final products = catalog.visible;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: catalog.load,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        const TextSpan(text: 'Clean'),
                        TextSpan(text: 'MN', style: TextStyle(color: theme.colorScheme.primary)),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (AppConfig.useMock)
                    const Chip(label: Text('Демо'), visualDensity: VisualDensity.compact),
                ]),
                Text('Цэвэрлэгээний бараа гэрт тань',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                TextField(
                  onChanged: catalog.setQuery,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Бүтээгдэхүүн хайх',
                    prefixIcon: Icon(Icons.search),
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 12),
                _Banner(),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 56,
              child: ListView(
                key: const Key('categories'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: [
                  _CatChip(label: 'Бүгд', selected: catalog.category == null,
                      onTap: () => catalog.setCategory(null)),
                  for (final c in ProductCategory.values)
                    _CatChip(
                      label: '${c.emoji} ${c.label}',
                      selected: catalog.category == c,
                      onTap: () => catalog.setCategory(catalog.category == c ? null : c),
                    ),
                ],
              ),
            ),
          ),
          if (catalog.loading && catalog.all.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (catalog.error != null && catalog.all.isEmpty)
            SliverFillRemaining(
              child: _Message(
                icon: Icons.wifi_off,
                text: catalog.error!,
                action: FilledButton.tonal(onPressed: catalog.load, child: const Text('Дахин оролдох')),
              ),
            )
          else if (products.isEmpty)
            const SliverFillRemaining(
                child: _Message(icon: Icons.search_off, text: 'Илэрц олдсонгүй'))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid(
                // Том фонттой үед карт өндөрсөнө (текст таслагдахгүй).
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio:
                      0.62 / MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0),
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => ProductCard(product: products[i]),
                  childCount: products.length,
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [scheme.primary, scheme.tertiary]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${formatMnt(AppConfig.freeDeliveryThreshold)}-с дээш',
                style: TextStyle(color: scheme.onPrimary, fontSize: 13)),
            Text('Хүргэлт үнэгүй!',
                style: TextStyle(color: scheme.onPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('QPay-ээр шууд төлөөрэй',
                style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.9), fontSize: 13)),
          ]),
        ),
        Icon(Icons.local_shipping_rounded, size: 48, color: scheme.onPrimary),
      ]),
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => onTap(),
        ),
      );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ]),
        ),
      );
}
