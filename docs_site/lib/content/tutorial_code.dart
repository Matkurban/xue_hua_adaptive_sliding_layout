// Complete, runnable `lib/main.dart` files for each tutorial step.
// Shared by both locales. Every file here was checked with `flutter analyze`
// (Flutter 3.47.7) and widget-tested against xue_hua_adaptive_sliding_layout 3.4.x.

const firstAppMain = r'''
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

// 1. One route table for the whole app.
final router = AdaptiveRouter(
  initialLocation: '/products',
  routes: [AdaptiveRoute(path: '/products', builder: (context, state) => const ProductsPage())],
);

void main() => runApp(const ShopApp());

// 2. Hand the router to MaterialApp.router.
class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(title: 'Shop', routerConfig: router);
  }
}

// 3. A normal Flutter page. Nothing package-specific here.
class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: const Center(child: Text('Hello from /products')),
    );
  }
}''';

const nestedRoutesMain = r'''
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

class Product {
  const Product(this.id, this.name, this.price);
  final int id;
  final String name;
  final double price;
}

const products = [
  Product(1, 'Coffee mug', 12),
  Product(2, 'Notebook', 8),
  Product(3, 'Desk lamp', 39),
];

Product? findProduct(String? id) {
  final value = int.tryParse(id ?? '');
  for (final product in products) {
    if (product.id == value) return product;
  }
  return null;
}

final router = AdaptiveRouter(
  initialLocation: '/products',
  routes: [
    AdaptiveRoute(
      path: '/products',
      builder: (context, state) => const ProductsPage(),
      routes: [
        // Child paths are relative: this matches /products/1, /products/2 ...
        AdaptiveRoute(
          path: ':id',
          builder: (context, state) => ProductDetailPage(id: state.pathParameters['id']),
        ),
      ],
    ),
  ],
);

void main() => runApp(const ShopApp());

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(title: 'Shop', routerConfig: router);
  }
}

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: ListView(
        children: [
          for (final product in products)
            ListTile(
              title: Text(product.name),
              subtitle: Text('\$${product.price}'),
              onTap: () => AdaptiveRouter.of(context).pushNamed('/products/${product.id}'),
            ),
        ],
      ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.id});

  final String? id;

  @override
  Widget build(BuildContext context) {
    final product = findProduct(id);
    // The query string is available too: /products/1?ref=home
    final ref = AdaptiveRouteState.of(context).queryParameters['ref'];
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => AdaptiveRouter.of(context).maybePop()),
        title: Text(product?.name ?? 'Not found'),
      ),
      body: Center(
        child: Text(
          product == null ? 'No product $id' : '\$${product.price}  (ref: ${ref ?? '-'})',
        ),
      ),
    );
  }
}''';

const navigationMain = r'''
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

class Product {
  const Product(this.id, this.name, this.price);
  final int id;
  final String name;
  final double price;
}

const products = [
  Product(1, 'Coffee mug', 12),
  Product(2, 'Notebook', 8),
  Product(3, 'Desk lamp', 39),
];

Product? findProduct(String? id) {
  final value = int.tryParse(id ?? '');
  for (final product in products) {
    if (product.id == value) return product;
  }
  return null;
}

final router = AdaptiveRouter(
  initialLocation: '/products',
  routes: [
    AdaptiveRoute(
      path: '/products',
      builder: (context, state) => const ProductsPage(),
      routes: [
        // Child paths are relative: this matches /products/1, /products/2 ...
        AdaptiveRoute(
          path: ':id',
          name: 'product', // lets you build locations with namedLocation
          builder: (context, state) => ProductDetailPage(id: state.pathParameters['id']),
          routes: [
            AdaptiveRoute(
              path: 'reviews', // /products/:id/reviews
              builder: (context, state) => const ReviewsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

void main() => runApp(const ShopApp());

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(title: 'Shop', routerConfig: router);
  }
}

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: ListView(
        children: [
          for (final product in products)
            ListTile(
              title: Text(product.name),
              subtitle: Text('\$${product.price}'),
              onTap: () => AdaptiveRouter.of(context).pushNamed('/products/${product.id}'),
            ),
        ],
      ),
    );
  }
}

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.id});

  final String? id;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int? _stars;

  @override
  Widget build(BuildContext context) {
    final product = findProduct(widget.id);
    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('No product ${widget.id}')),
      );
    }
    final router = AdaptiveRouter.of(context);
    final next = products[product.id % products.length]; // wraps around
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => router.maybePop()),
        title: Text(product.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('\$${product.price}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          // pushNamed returns a Future that completes with the value passed to pop.
          FilledButton(
            onPressed: () async {
              final stars = await router.pushNamed<int>('/products/${product.id}/reviews');
              if (stars != null && mounted) setState(() => _stars = stars);
            },
            child: Text(_stars == null ? 'Rate this product' : 'Your rating: $_stars stars'),
          ),
          // pushReplacementNamed swaps the top page: back still returns to the list.
          OutlinedButton(
            onPressed: () => router.pushReplacementNamed(
              router.namedLocation('product', pathParameters: {'id': '${next.id}'}),
            ),
            child: Text('Next: ${next.name}'),
          ),
          // pushNamedAndRemoveUntil with (_) => false rebuilds the whole stack from a URL.
          TextButton(
            onPressed: () => router.pushNamedAndRemoveUntil('/products', (_) => false),
            child: const Text('Back to the list'),
          ),
        ],
      ),
    );
  }
}

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => router.maybePop()),
        title: const Text('Rate'),
      ),
      body: ListView(
        children: [
          for (var stars = 5; stars >= 1; stars--)
            ListTile(
              title: Text('$stars stars'),
              // pop(result) completes the pushNamed Future on the previous page.
              onTap: () => router.pop(stars),
            ),
        ],
      ),
    );
  }
}''';

const tabsMain = r'''
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

class Product {
  const Product(this.id, this.name, this.price);
  final int id;
  final String name;
  final double price;
}

const products = [
  Product(1, 'Coffee mug', 12),
  Product(2, 'Notebook', 8),
  Product(3, 'Desk lamp', 39),
];

Product? findProduct(String? id) {
  final value = int.tryParse(id ?? '');
  for (final product in products) {
    if (product.id == value) return product;
  }
  return null;
}

final router = AdaptiveRouter(
  initialLocation: '/products',
  routes: [
    // One shell per app, at the top level. Each branch is a tab with its own stack.
    AdaptiveShellRoute(
      builder: (context, shell, child) => AppShell(shell: shell, child: child),
      branches: [
        AdaptiveBranch(
          routes: [
            AdaptiveRoute(
              path: '/products',
              builder: (context, state) => const ProductsPage(),
              routes: [
                // Child paths are relative: this matches /products/1, /products/2 ...
                AdaptiveRoute(
                  path: ':id',
                  name: 'product', // lets you build locations with namedLocation
                  builder: (context, state) => ProductDetailPage(id: state.pathParameters['id']),
                  routes: [
                    AdaptiveRoute(
                      path: 'reviews', // /products/:id/reviews
                      builder: (context, state) => const ReviewsPage(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        AdaptiveBranch(
          routes: [
            AdaptiveRoute(path: '/account', builder: (context, state) => const AccountPage()),
          ],
        ),
      ],
    ),
  ],
);

void main() => runApp(const ShopApp());

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(title: 'Shop', routerConfig: router);
  }
}

/// The host chrome: a bottom bar on phones, a rail on wider windows.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell, required this.child});

  final AdaptiveShellState shell;
  final Widget child;

  void _select(int index) {
    // Tapping the current tab again returns to that tab's first page.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (shell.isCompact) {
      // AdaptiveShellChrome puts the bar inside the branch page, so pushed pages can cover it.
      return AdaptiveShellChrome(
        bottomNavigationBar: (context) => NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: _select,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.storefront), label: 'Products'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Account'),
          ],
        ),
        child: child,
      );
    }
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _select,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.storefront), label: Text('Products')),
              NavigationRailDestination(icon: Icon(Icons.person), label: Text('Account')),
            ],
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: ListView(
        children: [
          for (final product in products)
            ListTile(
              title: Text(product.name),
              subtitle: Text('\$${product.price}'),
              onTap: () => AdaptiveRouter.of(context).pushNamed('/products/${product.id}'),
            ),
        ],
      ),
    );
  }
}

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.id});

  final String? id;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int? _stars;

  @override
  Widget build(BuildContext context) {
    final product = findProduct(widget.id);
    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('No product ${widget.id}')),
      );
    }
    final router = AdaptiveRouter.of(context);
    final next = products[product.id % products.length]; // wraps around
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => router.maybePop()),
        title: Text(product.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('\$${product.price}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          // pushNamed returns a Future that completes with the value passed to pop.
          FilledButton(
            onPressed: () async {
              final stars = await router.pushNamed<int>('/products/${product.id}/reviews');
              if (stars != null && mounted) setState(() => _stars = stars);
            },
            child: Text(_stars == null ? 'Rate this product' : 'Your rating: $_stars stars'),
          ),
          // pushReplacementNamed swaps the top page: back still returns to the list.
          OutlinedButton(
            onPressed: () => router.pushReplacementNamed(
              router.namedLocation('product', pathParameters: {'id': '${next.id}'}),
            ),
            child: Text('Next: ${next.name}'),
          ),
          // pushNamedAndRemoveUntil with (_) => false rebuilds the whole stack from a URL.
          TextButton(
            onPressed: () => router.pushNamedAndRemoveUntil('/products', (_) => false),
            child: const Text('Back to the list'),
          ),
        ],
      ),
    );
  }
}

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => router.maybePop()),
        title: const Text('Rate'),
      ),
      body: ListView(
        children: [
          for (var stars = 5; stars >= 1; stars--)
            ListTile(
              title: Text('$stars stars'),
              // pop(result) completes the pushNamed Future on the previous page.
              onTap: () => router.pop(stars),
            ),
        ],
      ),
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: const Center(child: Text('Signed out')),
    );
  }
}''';

const twoColumnsMain = r'''
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

class Product {
  const Product(this.id, this.name, this.price);
  final int id;
  final String name;
  final double price;
}

const products = [
  Product(1, 'Coffee mug', 12),
  Product(2, 'Notebook', 8),
  Product(3, 'Desk lamp', 39),
];

Product? findProduct(String? id) {
  final value = int.tryParse(id ?? '');
  for (final product in products) {
    if (product.id == value) return product;
  }
  return null;
}

final router = AdaptiveRouter(
  initialLocation: '/products',
  routes: [
    // One shell per app, at the top level. Each branch is a tab with its own stack.
    AdaptiveShellRoute(
      // Two columns from 840 logical pixels wide (this is the default; change it here).
      breakpoints: const LayoutBreakpoints(expandedMinWidth: 840),
      // Shown in the right column while only the list is open.
      placeholder: (context) => const Center(child: Text('Pick a product')),
      builder: (context, shell, child) => AppShell(shell: shell, child: child),
      branches: [
        AdaptiveBranch(
          routes: [
            AdaptiveRoute(
              path: '/products',
              builder: (context, state) => const ProductsPage(),
              routes: [
                // Child paths are relative: this matches /products/1, /products/2 ...
                AdaptiveRoute(
                  path: ':id',
                  name: 'product', // lets you build locations with namedLocation
                  builder: (context, state) => ProductDetailPage(id: state.pathParameters['id']),
                  routes: [
                    AdaptiveRoute(
                      path: 'reviews', // /products/:id/reviews
                      builder: (context, state) => const ReviewsPage(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        AdaptiveBranch(
          routes: [
            AdaptiveRoute(path: '/account', builder: (context, state) => const AccountPage()),
          ],
        ),
      ],
    ),
  ],
);

void main() => runApp(const ShopApp());

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(title: 'Shop', routerConfig: router);
  }
}

/// The host chrome: a bottom bar on phones, a rail on wider windows.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell, required this.child});

  final AdaptiveShellState shell;
  final Widget child;

  void _select(int index) {
    // Tapping the current tab again returns to that tab's first page.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (shell.isCompact) {
      // AdaptiveShellChrome puts the bar inside the branch page, so pushed pages can cover it.
      return AdaptiveShellChrome(
        bottomNavigationBar: (context) => NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: _select,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.storefront), label: 'Products'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Account'),
          ],
        ),
        child: child,
      );
    }
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _select,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.storefront), label: Text('Products')),
              NavigationRailDestination(icon: Icon(Icons.person), label: Text('Account')),
            ],
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: ListView(
        children: [
          for (final product in products)
            ListTile(
              title: Text(product.name),
              subtitle: Text('\$${product.price}'),
              onTap: () => AdaptiveRouter.of(context).pushNamed('/products/${product.id}'),
            ),
        ],
      ),
    );
  }
}

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.id});

  final String? id;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int? _stars;

  @override
  Widget build(BuildContext context) {
    final product = findProduct(widget.id);
    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('No product ${widget.id}')),
      );
    }
    final router = AdaptiveRouter.of(context);
    final next = products[product.id % products.length]; // wraps around
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => router.maybePop()),
        title: Text(product.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('\$${product.price}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          // pushNamed returns a Future that completes with the value passed to pop.
          FilledButton(
            onPressed: () async {
              final stars = await router.pushNamed<int>('/products/${product.id}/reviews');
              if (stars != null && mounted) setState(() => _stars = stars);
            },
            child: Text(_stars == null ? 'Rate this product' : 'Your rating: $_stars stars'),
          ),
          // pushReplacementNamed swaps the top page: back still returns to the list.
          OutlinedButton(
            onPressed: () => router.pushReplacementNamed(
              router.namedLocation('product', pathParameters: {'id': '${next.id}'}),
            ),
            child: Text('Next: ${next.name}'),
          ),
          // pushNamedAndRemoveUntil with (_) => false rebuilds the whole stack from a URL.
          TextButton(
            onPressed: () => router.pushNamedAndRemoveUntil('/products', (_) => false),
            child: const Text('Back to the list'),
          ),
        ],
      ),
    );
  }
}

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => router.maybePop()),
        title: const Text('Rate'),
      ),
      body: ListView(
        children: [
          for (var stars = 5; stars >= 1; stars--)
            ListTile(
              title: Text('$stars stars'),
              // pop(result) completes the pushNamed Future on the previous page.
              onTap: () => router.pop(stars),
            ),
        ],
      ),
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: const Center(child: Text('Signed out')),
    );
  }
}''';

const titlesMain = r'''
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

class Product {
  const Product(this.id, this.name, this.price);
  final int id;
  final String name;
  final double price;
}

const products = [
  Product(1, 'Coffee mug', 12),
  Product(2, 'Notebook', 8),
  Product(3, 'Desk lamp', 39),
];

Product? findProduct(String? id) {
  final value = int.tryParse(id ?? '');
  for (final product in products) {
    if (product.id == value) return product;
  }
  return null;
}

final router = AdaptiveRouter(
  initialLocation: '/products',
  routes: [
    // One shell per app, at the top level. Each branch is a tab with its own stack.
    AdaptiveShellRoute(
      // Two columns from 840 logical pixels wide (this is the default; change it here).
      showBreadcrumbs: true, // default: a crumb strip above the two columns
      breakpoints: const LayoutBreakpoints(expandedMinWidth: 840),
      // Shown in the right column while only the list is open.
      placeholder: (context) => const Center(child: Text('Pick a product')),
      builder: (context, shell, child) => AppShell(shell: shell, child: child),
      branches: [
        AdaptiveBranch(
          routes: [
            AdaptiveRoute(
              path: '/products',
              title: (state) => 'Products',
              builder: (context, state) => const ProductsPage(),
              routes: [
                // Child paths are relative: this matches /products/1, /products/2 ...
                AdaptiveRoute(
                  path: ':id',
                  name: 'product', // lets you build locations with namedLocation
                  // Evaluated once at match time, without a BuildContext.
                  title: (state) => findProduct(state.pathParameters['id'])?.name ?? 'Product',
                  builder: (context, state) => ProductDetailPage(id: state.pathParameters['id']),
                  routes: [
                    AdaptiveRoute(
                      path: 'reviews', // /products/:id/reviews
                      title: (state) => 'Rate',
                      builder: (context, state) => const ReviewsPage(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        AdaptiveBranch(
          routes: [
            AdaptiveRoute(
              path: '/account',
              title: (state) => 'Account',
              builder: (context, state) => const AccountPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

void main() => runApp(const ShopApp());

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(title: 'Shop', routerConfig: router);
  }
}

/// The host chrome: a bottom bar on phones, a rail on wider windows.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell, required this.child});

  final AdaptiveShellState shell;
  final Widget child;

  void _select(int index) {
    // Tapping the current tab again returns to that tab's first page.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (shell.isCompact) {
      // AdaptiveShellChrome puts the bar inside the branch page, so pushed pages can cover it.
      return AdaptiveShellChrome(
        bottomNavigationBar: (context) => NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: _select,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.storefront), label: 'Products'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Account'),
          ],
        ),
        child: child,
      );
    }
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _select,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.storefront), label: Text('Products')),
              NavigationRailDestination(icon: Icon(Icons.person), label: Text('Account')),
            ],
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: ListView(
        children: [
          for (final product in products)
            ListTile(
              title: Text(product.name),
              subtitle: Text('\$${product.price}'),
              onTap: () => AdaptiveRouter.of(context).pushNamed('/products/${product.id}'),
            ),
        ],
      ),
    );
  }
}

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.id});

  final String? id;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int? _stars;

  @override
  Widget build(BuildContext context) {
    final product = findProduct(widget.id);
    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('No product ${widget.id}')),
      );
    }
    final router = AdaptiveRouter.of(context);
    final next = products[product.id % products.length]; // wraps around
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => router.maybePop()),
        title: Text(product.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('\$${product.price}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          // pushNamed returns a Future that completes with the value passed to pop.
          FilledButton(
            onPressed: () async {
              final stars = await router.pushNamed<int>('/products/${product.id}/reviews');
              if (stars != null && mounted) setState(() => _stars = stars);
            },
            child: Text(_stars == null ? 'Rate this product' : 'Your rating: $_stars stars'),
          ),
          // pushReplacementNamed swaps the top page: back still returns to the list.
          OutlinedButton(
            onPressed: () => router.pushReplacementNamed(
              router.namedLocation('product', pathParameters: {'id': '${next.id}'}),
            ),
            child: Text('Next: ${next.name}'),
          ),
          // pushNamedAndRemoveUntil with (_) => false rebuilds the whole stack from a URL.
          TextButton(
            onPressed: () => router.pushNamedAndRemoveUntil('/products', (_) => false),
            child: const Text('Back to the list'),
          ),
        ],
      ),
    );
  }
}

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => router.maybePop()),
        title: const Text('Rate'),
      ),
      body: ListView(
        children: [
          for (var stars = 5; stars >= 1; stars--)
            ListTile(
              title: Text('$stars stars'),
              // pop(result) completes the pushNamed Future on the previous page.
              onTap: () => router.pop(stars),
            ),
        ],
      ),
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: const Center(child: Text('Signed out')),
    );
  }
}''';

const redirectsMain = r'''
import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

// App state kept outside the widget tree (signals_flutter is already a dependency).
final signedIn = signal(false);
final profileDirty = signal(false);

class Product {
  const Product(this.id, this.name, this.price);
  final int id;
  final String name;
  final double price;
}

const products = [
  Product(1, 'Coffee mug', 12),
  Product(2, 'Notebook', 8),
  Product(3, 'Desk lamp', 39),
];

Product? findProduct(String? id) {
  final value = int.tryParse(id ?? '');
  for (final product in products) {
    if (product.id == value) return product;
  }
  return null;
}

final router = AdaptiveRouter(
  initialLocation: '/products',
  // Runs before every navigation. Return a location to go there instead.
  redirect: (context, state) {
    if (state.uri.path.startsWith('/account/profile') && !signedIn.value) {
      return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
    }
    return null;
  },
  routes: [
    // Outside the shell and fullscreen: covers the tabs at every width.
    AdaptiveRoute(
      path: '/login',
      fullscreen: true,
      builder: (context, state) => LoginPage(from: state.queryParameters['from']),
    ),
    // One shell per app, at the top level. Each branch is a tab with its own stack.
    AdaptiveShellRoute(
      // Two columns from 840 logical pixels wide (this is the default; change it here).
      showBreadcrumbs: true, // default: a crumb strip above the two columns
      breakpoints: const LayoutBreakpoints(expandedMinWidth: 840),
      // Shown in the right column while only the list is open.
      placeholder: (context) => const Center(child: Text('Pick a product')),
      builder: (context, shell, child) => AppShell(shell: shell, child: child),
      branches: [
        AdaptiveBranch(
          routes: [
            AdaptiveRoute(
              path: '/products',
              title: (state) => 'Products',
              builder: (context, state) => const ProductsPage(),
              routes: [
                // Child paths are relative: this matches /products/1, /products/2 ...
                AdaptiveRoute(
                  path: ':id',
                  name: 'product', // lets you build locations with namedLocation
                  // Evaluated once at match time, without a BuildContext.
                  title: (state) => findProduct(state.pathParameters['id'])?.name ?? 'Product',
                  builder: (context, state) => ProductDetailPage(id: state.pathParameters['id']),
                  routes: [
                    AdaptiveRoute(
                      path: 'reviews', // /products/:id/reviews
                      title: (state) => 'Rate',
                      builder: (context, state) => const ReviewsPage(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        AdaptiveBranch(
          routes: [
            AdaptiveRoute(
              path: '/account',
              title: (state) => 'Account',
              builder: (context, state) => const AccountPage(),
              routes: [
                AdaptiveRoute(
                  path: 'profile',
                  title: (state) => 'Profile',
                  // Return false to cancel leaving (back button, system back, browser back).
                  onExit: (context, state) async {
                    if (!profileDirty.value) return true;
                    final leave = await showDialog<bool>(
                      context: context,
                      // Inside a pane, use the root navigator so the dialog is not clipped.
                      useRootNavigator: AdaptivePaneScope.maybeOf(context) != null,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Discard changes?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: const Text('Stay'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('Discard'),
                          ),
                        ],
                      ),
                    );
                    if (leave == true) profileDirty.value = false;
                    return leave == true;
                  },
                  builder: (context, state) => const ProfilePage(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

void main() => runApp(const ShopApp());

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(title: 'Shop', routerConfig: router);
  }
}

/// The host chrome: a bottom bar on phones, a rail on wider windows.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell, required this.child});

  final AdaptiveShellState shell;
  final Widget child;

  void _select(int index) {
    // Tapping the current tab again returns to that tab's first page.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (shell.isCompact) {
      // AdaptiveShellChrome puts the bar inside the branch page, so pushed pages can cover it.
      return AdaptiveShellChrome(
        bottomNavigationBar: (context) => NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: _select,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.storefront), label: 'Products'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Account'),
          ],
        ),
        child: child,
      );
    }
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _select,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.storefront), label: Text('Products')),
              NavigationRailDestination(icon: Icon(Icons.person), label: Text('Account')),
            ],
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: ListView(
        children: [
          for (final product in products)
            ListTile(
              title: Text(product.name),
              subtitle: Text('\$${product.price}'),
              onTap: () => AdaptiveRouter.of(context).pushNamed('/products/${product.id}'),
            ),
        ],
      ),
    );
  }
}

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.id});

  final String? id;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int? _stars;

  @override
  Widget build(BuildContext context) {
    final product = findProduct(widget.id);
    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('No product ${widget.id}')),
      );
    }
    final router = AdaptiveRouter.of(context);
    final next = products[product.id % products.length]; // wraps around
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => router.maybePop()),
        title: Text(product.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('\$${product.price}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          // pushNamed returns a Future that completes with the value passed to pop.
          FilledButton(
            onPressed: () async {
              final stars = await router.pushNamed<int>('/products/${product.id}/reviews');
              if (stars != null && mounted) setState(() => _stars = stars);
            },
            child: Text(_stars == null ? 'Rate this product' : 'Your rating: $_stars stars'),
          ),
          // pushReplacementNamed swaps the top page: back still returns to the list.
          OutlinedButton(
            onPressed: () => router.pushReplacementNamed(
              router.namedLocation('product', pathParameters: {'id': '${next.id}'}),
            ),
            child: Text('Next: ${next.name}'),
          ),
          // pushNamedAndRemoveUntil with (_) => false rebuilds the whole stack from a URL.
          TextButton(
            onPressed: () => router.pushNamedAndRemoveUntil('/products', (_) => false),
            child: const Text('Back to the list'),
          ),
        ],
      ),
    );
  }
}

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => router.maybePop()),
        title: const Text('Rate'),
      ),
      body: ListView(
        children: [
          for (var stars = 5; stars >= 1; stars--)
            ListTile(
              title: Text('$stars stars'),
              // pop(result) completes the pushNamed Future on the previous page.
              onTap: () => router.pop(stars),
            ),
        ],
      ),
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SignalBuilder(
        builder: (context) => ListView(
          children: [
            ListTile(title: Text(signedIn.value ? 'Signed in' : 'Signed out')),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit profile'),
              // Signed out? The redirect sends you to /login?from=/account/profile.
              onTap: () => router.pushNamed('/account/profile'),
            ),
            if (signedIn.value)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () {
                  signedIn.value = false;
                  router.refresh(); // re-run redirect for the current location
                },
              ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key, this.from});

  final String? from;

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => router.maybePop()),
        title: const Text('Sign in'),
      ),
      body: Center(
        child: FilledButton(
          onPressed: () {
            signedIn.value = true;
            // Rebuild the stack from the URL the user originally asked for.
            router.pushNamedAndRemoveUntil(from ?? '/account', (_) => false);
          },
          child: const Text('Sign in'),
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => AdaptiveRouter.of(context).maybePop()),
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          decoration: const InputDecoration(labelText: 'Display name'),
          onChanged: (_) => profileDirty.value = true,
        ),
      ),
    );
  }
}''';

const layoutWithoutRouterMain = r'''
import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

void main() => runApp(const MaterialApp(home: FolderBrowser()));

/// A drill-down browser built only from the layout widgets: no router, no URLs.
class FolderBrowser extends StatefulWidget {
  const FolderBrowser({super.key});

  @override
  State<FolderBrowser> createState() => _FolderBrowserState();
}

class _FolderBrowserState extends State<FolderBrowser> {
  // The stack is just a list you own. Each entry becomes one pane.
  final List<String> _path = ['Home'];
  double _leftFraction = 0.4;

  void _open(String name) => setState(() => _path.add(name));

  void _popTo(int depth) => setState(() => _path.removeRange(depth + 1, _path.length));

  @override
  Widget build(BuildContext context) {
    const breakpoints = LayoutBreakpoints();
    final width = MediaQuery.sizeOf(context).width;
    final panes = [
      for (var i = 0; i < _path.length; i++)
        SlidingPane(
          // Keys must stay stable while the depth changes so pane state survives.
          key: ValueKey('pane-$i-${_path[i]}'),
          title: signal(_path[i]),
          child: FolderPage(name: _path[i], onOpen: _open),
        ),
    ];
    return Scaffold(
      body: Column(
        children: [
          AdaptiveBreadcrumbs(panes: panes, onSelect: (pane) => _popTo(panes.indexOf(pane))),
          Expanded(
            child: SlidingPaneViewport(
              panes: panes,
              visibleCount: breakpoints.visibleColumnCount(width), // 1 or 2
              resizeHandleWidth: 4,
              leftPaneFraction: _leftFraction,
              onLeftPaneFractionChanged: (value) => setState(() => _leftFraction = value),
              onPop: _path.length > 1 ? () => _popTo(_path.length - 2) : null,
              placeholder: const Center(child: Text('Open a folder')),
            ),
          ),
        ],
      ),
    );
  }
}

class FolderPage extends StatelessWidget {
  const FolderPage({super.key, required this.name, required this.onOpen});

  final String name;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        children: [
          for (final child in ['Docs', 'Photos', 'Music'])
            ListTile(
              leading: const Icon(Icons.folder),
              title: Text(child),
              onTap: () => onOpen('$name/$child'),
            ),
        ],
      ),
    );
  }
}''';
