import 'package:flutter/material.dart';

import '../app.dart';
import '../services/account_store.dart';
import '../widgets/common.dart';

/// Stores and products favourited from the MarketGO storefront (stored
/// locally on the device).
class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAF9),
        surfaceTintColor: Colors.transparent,
        title: const Text('Favourites'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: MoversApp.brandOrangeDark,
          indicatorColor: MoversApp.brandOrange,
          unselectedLabelColor: const Color(0xFF6B7280),
          tabs: const [
            Tab(text: 'Stores'),
            Tab(text: 'Products'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          ListenableBuilder(
            listenable: AccountStore.instance,
            builder: (context, _) {
              final stores = AccountStore.instance.favouriteStores;
              if (stores.isEmpty) {
                return const _EmptyFavourites(
                  icon: Icons.storefront_outlined,
                  message: 'Stores you favourite from the MarketGO storefront '
                      'will show up here.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                itemCount: stores.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final s = stores[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEAF0EE)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: MoversApp.brandOrangeLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.storefront_rounded,
                              color: MoversApp.brandOrangeDark),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              if (s.tagline.isNotEmpty)
                                Text(s.tagline,
                                    style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => AccountStore.instance
                              .toggleFavouriteStore(s),
                          icon: Icon(Icons.favorite_rounded,
                              color: MoversApp.brandOrangeDark),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          ListenableBuilder(
            listenable: AccountStore.instance,
            builder: (context, _) {
              final products = AccountStore.instance.favouriteProducts;
              if (products.isEmpty) {
                return const _EmptyFavourites(
                  icon: Icons.favorite_border_rounded,
                  message: 'Products you favourite from the MarketGO storefront '
                      'will show up here.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final p = products[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEAF0EE)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: MoversApp.brandOrangeLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.inventory_2_rounded,
                              color: MoversApp.brandOrangeDark),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              Text('${p.vendorName} · ${p.unit}',
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        Text(formatPrice(p.price),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13)),
                        IconButton(
                          onPressed: () => AccountStore.instance
                              .toggleFavouriteProduct(p),
                          icon: Icon(Icons.favorite_rounded,
                              color: MoversApp.brandOrangeDark),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyFavourites extends StatelessWidget {
  const _EmptyFavourites({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF9AA1AA)),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}