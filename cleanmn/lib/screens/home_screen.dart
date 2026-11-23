import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/product.dart';
import '../state/catalog_provider.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/product_card.dart';
import 'shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.scroll, required this.search});

  final ScrollController scroll;
  final TextEditingController search;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final products = catalog.visible;
    final popular = catalog.isHome ? catalog.popular() : const <Product>[];

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: catalog.load,
        child: CustomScrollView(
          controller: scroll,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('menu'),
                      tooltip: 'Цэс',
                      icon: const Icon(Icons.menu_rounded, size: 28),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _Logo(onTap: () => AppShell.of(context)?.goHome()),
                      ),
                    ),
                    if (AppConfig.useMock)
                      const Chip(label: Text('Демо'), visualDensity: VisualDensity.compact),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: search,
                      onChanged: catalog.setQuery,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Бүтээгдэхүүн хайх',
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: EdgeInsets.zero,
                        suffixIcon: catalog.query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Цэвэрлэх',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  search.clear();
                                  catalog.setQuery('');
                                },
                              ),
                      ),
                    ),
                    if (catalog.isHome) ...[const SizedBox(height: 14), const _Banner()],
                  ],
                ),
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
                    _CatChip(
                      label: 'Бүгд',
                      selected: catalog.category == null,
                      onTap: () => catalog.setCategory(null),
                    ),
                    for (final c in ProductCategory.values)
                      _CatChip(
                        emoji: c.emoji,
                        label: c.label,
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
            else ...[
              if (popular.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: _SectionTitle(
                    icon: Icons.local_fire_department_rounded,
                    text: 'Хамгийн их захиалсан',
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 268 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6),
                    child: ListView.separated(
                      key: const Key('popular'),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      itemCount: popular.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => SizedBox(
                        width: 164,
                        child: ProductCard(product: popular[i], rank: i + 1, hero: false),
                      ),
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: _SectionTitle(
                  icon: catalog.category == null ? Icons.grid_view_rounded : Icons.category_outlined,
                  text:
                      catalog.category?.label ??
                      (catalog.query.trim().isEmpty ? 'Бүх бараа' : 'Хайлтын илэрц'),
                  trailing: '${products.length} бараа',
                ),
              ),
              if (products.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _Message(icon: Icons.search_off, text: 'Илэрц олдсонгүй'),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    // Том фонттой үед карт өндөрсөнө (текст таслагдахгүй).
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.62 / MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0),
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => ProductCard(product: products[i]),
                      childCount: products.length,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "CleanMN" лого — дарахад нүүр хуудас руу буцна.
class _Logo extends StatelessWidget {
  const _Logo({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'CleanMN нүүр хуудас',
      excludeSemantics: true,
      child: InkWell(
        key: const Key('logo'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Clean',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                TextSpan(
                  text: 'MN',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.text, this.trailing});
  final IconData icon;
  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: icon == Icons.local_fire_department_rounded ? Brand.peach : theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Brand.mint, Brand.sky],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatMnt(AppConfig.freeDeliveryThreshold)}-с дээш',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const Text(
                  'Хүргэлт үнэгүй!',
                  style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'QPay-ээр шууд төлөөрэй',
                  style: TextStyle(color: Color(0xF2FFFFFF), fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: Color(0x33FFFFFF), shape: BoxShape.circle),
            child: const Icon(Icons.local_shipping_rounded, size: 30, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Ангиллын чип. Emoji-г тогтмол хэмжээтэй avatar дотор тусад нь харуулдаг:
/// вэб дээр emoji фонт хожуу ачаалагдахад шошгоны текст таслагдахаас сэргийлнэ.
class _CatChip extends StatelessWidget {
  const _CatChip({this.emoji, required this.label, required this.selected, required this.onTap});
  final String? emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      avatar: emoji == null
          ? null
          : SizedBox.square(
              dimension: 18,
              child: FittedBox(child: Text(emoji!, textAlign: TextAlign.center)),
            ),
      label: Text(label, maxLines: 1, softWrap: false),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}
